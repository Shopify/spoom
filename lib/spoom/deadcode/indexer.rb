# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Indexer < SyntaxTree::Visitor
      extend T::Sig

      sig { returns(String) }
      attr_reader :path, :file_name

      sig { returns(Index) }
      attr_reader :index

      sig { params(path: String, source: String, index: Index).void }
      def initialize(path, source, index)
        super()

        @path = path
        @file_name = T.let(File.basename(path), String)
        @source = source
        @index = index
        @previous_node = T.let(nil, T.nilable(SyntaxTree::Node))
        @names_nesting = T.let([], T::Array[String])
        @nodes_nesting = T.let([], T::Array[SyntaxTree::Node])
        @in_const_field = T.let(false, T::Boolean)
        @in_opassign = T.let(false, T::Boolean)
        @in_symbol_literal = T.let(false, T::Boolean)
      end

      # Visit

      sig { override.params(node: T.nilable(SyntaxTree::Node)).void }
      def visit(node)
        return unless node

        @nodes_nesting << node
        super
        @nodes_nesting.pop
        @previous_node = node
      end

      sig { override.params(node: SyntaxTree::AliasNode).void }
      def visit_alias(node)
        reference_method(node_string(node.right), node)
      end

      sig { override.params(node: SyntaxTree::ARef).void }
      def visit_aref(node)
        super

        reference_method("[]", node)
      end

      sig { override.params(node: SyntaxTree::ARefField).void }
      def visit_aref_field(node)
        super

        reference_method("[]=", node)
      end

      sig { override.params(node: SyntaxTree::ArgBlock).void }
      def visit_arg_block(node)
        value = node.value

        case value
        when SyntaxTree::SymbolLiteral
          # If the block call is something like `x.select(&:foo)`, we need to reference the `foo` method
          reference_method(symbol_string(value), node)
        when SyntaxTree::VCall
          # If the block call is something like `x.select { ... }`, we need to visit the block
          super
        end
      end

      sig { override.params(node: SyntaxTree::Binary).void }
      def visit_binary(node)
        super

        op = node.operator

        # Reference the operator itself
        reference_method(op.to_s, node)

        case op
        when :<, :>, :<=, :>=
          # For comparison operators, we also reference the `<=>` method
          reference_method("<=>", node)
        end
      end

      sig { override.params(node: SyntaxTree::CallNode).void }
      def visit_call(node)
        visit_send(
          Send.new(
            node: node,
            name: node_string(node.message),
            recv: node.receiver,
            args: call_args(node.arguments),
          ),
        )
      end

      sig { override.params(node: SyntaxTree::ClassDeclaration).void }
      def visit_class(node)
        const_name = node_string(node.constant)
        @names_nesting << const_name
        define_class(T.must(const_name.split("::").last), @names_nesting.join("::"), node)

        # We do not call `super` here because we don't want to visit the `constant` again
        visit(node.superclass) if node.superclass
        visit(node.bodystmt)

        @names_nesting.pop
      end

      sig { override.params(node: SyntaxTree::Command).void }
      def visit_command(node)
        visit_send(
          Send.new(
            node: node,
            name: node_string(node.message),
            args: call_args(node.arguments),
            block: node.block,
          ),
        )
      end

      sig { override.params(node: SyntaxTree::CommandCall).void }
      def visit_command_call(node)
        visit_send(
          Send.new(
            node: node,
            name: node_string(node.message),
            recv: node.receiver,
            args: call_args(node.arguments),
            block: node.block,
          ),
        )
      end

      sig { override.params(node: SyntaxTree::Const).void }
      def visit_const(node)
        reference_constant(node.value, node) unless @in_symbol_literal
      end

      sig { override.params(node: SyntaxTree::ConstPathField).void }
      def visit_const_path_field(node)
        # We do not call `super` here because we don't want to visit the `constant` again
        visit(node.parent)

        name = node.constant.value
        full_name = [*@names_nesting, node_string(node.parent), name].join("::")
        define_constant(name, full_name, node)
      end

      sig { override.params(node: SyntaxTree::DefNode).void }
      def visit_def(node)
        super

        name = node_string(node.name)
        define_method(name, [*@names_nesting, name].join("::"), node)
      end

      sig { override.params(node: SyntaxTree::Field).void }
      def visit_field(node)
        visit(node.parent)

        name = node.name
        case name
        when SyntaxTree::Const
          name = name.value
          full_name = [*@names_nesting, node_string(node.parent), name].join("::")
          define_constant(name, full_name, node)
        when SyntaxTree::Ident
          reference_method(name.value, node) if @in_opassign
          reference_method("#{name.value}=", node)
        end
      end

      sig { override.params(node: SyntaxTree::ModuleDeclaration).void }
      def visit_module(node)
        const_name = node_string(node.constant)
        @names_nesting << const_name
        define_module(T.must(const_name.split("::").last), @names_nesting.join("::"), node)

        # We do not call `super` here because we don't want to visit the `constant` again
        visit(node.bodystmt)

        @names_nesting.pop
      end

      sig { override.params(node: SyntaxTree::OpAssign).void }
      def visit_opassign(node)
        # Both `FOO = x` and `FOO += x` yield a VarField node, but the former is a constant definition and the latter is
        # a constant reference. We need to distinguish between the two cases.
        @in_opassign = true
        super
        @in_opassign = false
      end

      sig { params(send: Send).void }
      def visit_send(send)
        visit(send.recv)

        case send.name
        when "attr_reader"
          send.args.each do |arg|
            next unless arg.is_a?(SyntaxTree::SymbolLiteral)

            name = symbol_string(arg)
            define_attr_reader(name, [*@names_nesting, name].join("::"), arg)
          end
        when "attr_writer"
          send.args.each do |arg|
            next unless arg.is_a?(SyntaxTree::SymbolLiteral)

            name = symbol_string(arg)
            define_attr_writer("#{name}=", "#{[*@names_nesting, name].join("::")}=", arg)
          end
        when "attr_accessor"
          send.args.each do |arg|
            next unless arg.is_a?(SyntaxTree::SymbolLiteral)

            name = symbol_string(arg)
            full_name = [*@names_nesting, name].join("::")
            define_attr_reader(name, full_name, arg)
            define_attr_writer("#{name}=", "#{full_name}=", arg)
          end
        else
          reference_method(send.name, send.node)
          visit_all(send.args)
          visit(send.block)
        end
      end

      sig { override.params(node: SyntaxTree::SymbolLiteral).void }
      def visit_symbol_literal(node)
        # Something like `:FOO` will yield a Const node but we do not want to treat it as a constant reference.
        # So we need to distinguish between the two cases.
        @in_symbol_literal = true
        super
        @in_symbol_literal = false
      end

      sig { override.params(node: SyntaxTree::TopConstField).void }
      def visit_top_const_field(node)
        define_constant(node.constant.value, node.constant.value, node)
      end

      sig { override.params(node: SyntaxTree::VarField).void }
      def visit_var_field(node)
        value = node.value
        case value
        when SyntaxTree::Const
          if @in_opassign
            reference_constant(value.value, node)
          else
            name = value.value
            define_constant(name, [*@names_nesting, name].join("::"), node)
          end
        when SyntaxTree::Ident
          reference_method(value.value, node) if @in_opassign
          reference_method("#{value.value}=", node)
        end
      end

      sig { override.params(node: SyntaxTree::VCall).void }
      def visit_vcall(node)
        visit_send(Send.new(node: node, name: node_string(node.value)))
      end

      private

      # Definition indexing

      sig { params(name: String, full_name: String, node: SyntaxTree::Node).void }
      def define_attr_reader(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::AttrReader,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
      end

      sig { params(name: String, full_name: String, node: SyntaxTree::Node).void }
      def define_attr_writer(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::AttrWriter,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
      end

      sig { params(name: String, full_name: String, node: SyntaxTree::Node).void }
      def define_class(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::Class,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
      end

      sig { params(name: String, full_name: String, node: SyntaxTree::Node).void }
      def define_constant(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::Constant,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
      end

      sig { params(name: String, full_name: String, node: SyntaxTree::Node).void }
      def define_method(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::Method,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
      end

      sig { params(name: String, full_name: String, node: SyntaxTree::Node).void }
      def define_module(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::Module,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
      end

      # Reference indexing

      sig { params(name: String, node: SyntaxTree::Node).void }
      def reference_constant(name, node)
        @index.reference(Reference.new(name: name, kind: Reference::Kind::Constant, location: node_location(node)))
      end

      sig { params(name: String, node: SyntaxTree::Node).void }
      def reference_method(name, node)
        @index.reference(Reference.new(name: name, kind: Reference::Kind::Method, location: node_location(node)))
      end

      # Node utils

      sig { params(node: T.any(Symbol, SyntaxTree::Node)).returns(String) }
      def node_string(node)
        case node
        when Symbol
          node.to_s
        else
          T.must(@source[node.location.start_char...node.location.end_char])
        end
      end

      sig { params(node: SyntaxTree::Node).returns(Location) }
      def node_location(node)
        Location.from_syntax_tree(@path, node.location)
      end

      sig { params(node: SyntaxTree::Node).returns(String) }
      def symbol_string(node)
        node_string(node).delete_prefix(":")
      end

      sig do
        params(
          node: T.any(SyntaxTree::Args, SyntaxTree::ArgParen, SyntaxTree::ArgsForward, NilClass),
        ).returns(T::Array[SyntaxTree::Node])
      end
      def call_args(node)
        case node
        when SyntaxTree::ArgParen
          call_args(node.arguments)
        when SyntaxTree::Args
          node.parts
        else
          []
        end
      end
    end
  end
end
