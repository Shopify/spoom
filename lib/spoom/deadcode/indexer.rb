# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Indexer < Visitor
      extend T::Sig

      sig { returns(String) }
      attr_reader :path

      sig { returns(Index) }
      attr_reader :index

      sig { params(path: String, source: String, index: Index, plugins: T::Array[Plugins::Base]).void }
      def initialize(path, source, index, plugins: [])
        super()

        @path = path
        @file_name = T.let(File.basename(path), String)
        @source = source
        @index = index
        @plugins = plugins
        @previous_node = T.let(nil, T.nilable(Prism::Node))
        @names_nesting = T.let([], T::Array[String])
        @nodes_nesting = T.let([], T::Array[Prism::Node])
        @in_const_field = T.let(false, T::Boolean)
        @in_opassign = T.let(false, T::Boolean)
        @in_symbol_literal = T.let(false, T::Boolean)
      end

      # Visit

      sig { override.params(node: T.nilable(Prism::Node)).void }
      def visit(node)
        return unless node

        @nodes_nesting << node
        super
        @nodes_nesting.pop
        @previous_node = node
      end

      sig { override.params(node: Prism::AliasMethodNode).void }
      def visit_alias_method_node(node)
        reference_method(node.old_name.slice, node)
      end

      sig { override.params(node: Prism::AndNode).void }
      def visit_and_node(node)
        reference_method(node.operator_loc.slice, node)
        super
      end

      sig { override.params(node: Prism::BlockArgumentNode).void }
      def visit_block_argument_node(node)
        expression = node.expression
        case expression
        when Prism::SymbolNode
          reference_method(expression.unescaped, expression)
        else
          visit(expression)
        end
      end

      sig { override.params(node: Prism::CallAndWriteNode).void }
      def visit_call_and_write_node(node)
        visit(node.receiver)
        reference_method(node.read_name.to_s, node)
        reference_method(node.write_name.to_s, node)
        visit(node.value)
      end

      sig { override.params(node: Prism::CallOperatorWriteNode).void }
      def visit_call_operator_write_node(node)
        visit(node.receiver)
        reference_method(node.read_name.to_s, node)
        reference_method(node.write_name.to_s, node)
        visit(node.value)
      end

      sig { override.params(node: Prism::CallOrWriteNode).void }
      def visit_call_or_write_node(node)
        visit(node.receiver)
        reference_method(node.read_name.to_s, node)
        reference_method(node.write_name.to_s, node)
        visit(node.value)
      end

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        visit_send(
          Send.new(
            node: node,
            name: node.name.to_s,
            recv: node.receiver,
            args: node.arguments&.arguments || [],
            block: node.block,
          ),
        )
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        constant_path = node.constant_path.slice

        if constant_path.start_with?("::")
          full_name = constant_path.delete_prefix("::")

          # We found a top level definition such as `class ::A; end`, we need to reset the name nesting
          old_nesting = @names_nesting.dup
          @names_nesting.clear
          @names_nesting << full_name

          # We do not call `super` here because we don't want to visit the `constant` again
          visit(node.superclass) if node.superclass
          visit(node.body)

          # Restore the name nesting once we finished visited the class
          @names_nesting.clear
          @names_nesting = old_nesting
        else
          @names_nesting << constant_path

          # We do not call `super` here because we don't want to visit the `constant` again
          visit(node.superclass) if node.superclass
          visit(node.body)

          @names_nesting.pop
        end
      end

      sig { override.params(node: Prism::ConstantAndWriteNode).void }
      def visit_constant_and_write_node(node)
        reference_constant(node.name.to_s, node)
        visit(node.value)
      end

      sig { override.params(node: Prism::ConstantOperatorWriteNode).void }
      def visit_constant_operator_write_node(node)
        reference_constant(node.name.to_s, node)
        visit(node.value)
      end

      sig { override.params(node: Prism::ConstantOrWriteNode).void }
      def visit_constant_or_write_node(node)
        reference_constant(node.name.to_s, node)
        visit(node.value)
      end

      sig { override.params(node: Prism::ConstantPathNode).void }
      def visit_constant_path_node(node)
        parent = node.parent

        visit(parent) if parent
        reference_constant(node.name.to_s, node)
      end

      sig { override.params(node: Prism::ConstantPathWriteNode).void }
      def visit_constant_path_write_node(node)
        visit(node.target.parent)
        visit(node.value)
      end

      sig { override.params(node: Prism::ConstantReadNode).void }
      def visit_constant_read_node(node)
        reference_constant(node.name.to_s, node)
      end

      sig { override.params(node: Prism::ConstantWriteNode).void }
      def visit_constant_write_node(node)
        visit(node.value)
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        name = node.name.to_s
        define_method(name, [*@names_nesting, name].join("::"), node)

        super
      end

      sig { override.params(node: Prism::LocalVariableAndWriteNode).void }
      def visit_local_variable_and_write_node(node)
        name = node.name.to_s
        reference_method(name, node)
        reference_method("#{name}=", node)
        visit(node.value)
      end

      sig { override.params(node: Prism::LocalVariableOperatorWriteNode).void }
      def visit_local_variable_operator_write_node(node)
        name = node.name.to_s
        reference_method(name, node)
        reference_method("#{name}=", node)
        visit(node.value)
      end

      sig { override.params(node: Prism::LocalVariableOrWriteNode).void }
      def visit_local_variable_or_write_node(node)
        name = node.name.to_s
        reference_method(name, node)
        reference_method("#{name}=", node)
        visit(node.value)
      end

      sig { override.params(node: Prism::LocalVariableWriteNode).void }
      def visit_local_variable_write_node(node)
        visit(node.value)
        reference_method("#{node.name}=", node)
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        constant_path = node.constant_path.slice

        if constant_path.start_with?("::")
          full_name = constant_path.delete_prefix("::")

          # We found a top level definition such as `class ::A; end`, we need to reset the name nesting
          old_nesting = @names_nesting.dup
          @names_nesting.clear
          @names_nesting << full_name

          visit(node.body)

          # Restore the name nesting once we finished visited the class
          @names_nesting.clear
          @names_nesting = old_nesting
        else
          @names_nesting << constant_path

          # We do not call `super` here because we don't want to visit the `constant` again
          visit(node.body)

          @names_nesting.pop
        end
      end

      sig { override.params(node: Prism::MultiWriteNode).void }
      def visit_multi_write_node(node)
        node.lefts.each do |const|
          case const
          when Prism::LocalVariableTargetNode
            reference_method("#{const.name}=", node)
          end
        end
        visit(node.value)
      end

      sig { override.params(node: Prism::OrNode).void }
      def visit_or_node(node)
        reference_method(node.operator_loc.slice, node)
        super
      end

      sig { params(send: Send).void }
      def visit_send(send)
        visit(send.recv)

        case send.name
        when "attr_reader"
          send.args.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            name = arg.unescaped
            define_attr_reader(name, [*@names_nesting, name].join("::"), arg)
          end
        when "attr_writer"
          send.args.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            name = arg.unescaped
            define_attr_writer("#{name}=", "#{[*@names_nesting, name].join("::")}=", arg)
          end
        when "attr_accessor"
          send.args.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            name = arg.unescaped
            full_name = [*@names_nesting, name].join("::")
            define_attr_reader(name, full_name, arg)
            define_attr_writer("#{name}=", "#{full_name}=", arg)
          end
        else
          @plugins.each do |plugin|
            plugin.internal_on_send(self, send)
          end

          reference_method(send.name, send.node)

          case send.name
          when "<", ">", "<=", ">="
            # For comparison operators, we also reference the `<=>` method
            reference_method("<=>", send.node)
          end

          visit_all(send.args)
          visit(send.block)
        end
      end

      # Definition indexing

      sig { params(name: String, full_name: String, node: Prism::Node).void }
      def define_attr_reader(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::AttrReader,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
        @plugins.each { |plugin| plugin.internal_on_define_accessor(self, definition) }
      end

      sig { params(name: String, full_name: String, node: Prism::Node).void }
      def define_attr_writer(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::AttrWriter,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
        @plugins.each { |plugin| plugin.internal_on_define_accessor(self, definition) }
      end

      sig { params(name: String, full_name: String, node: Prism::Node).void }
      def define_method(name, full_name, node)
        definition = Definition.new(
          kind: Definition::Kind::Method,
          name: name,
          full_name: full_name,
          location: node_location(node),
        )
        @index.define(definition)
        @plugins.each { |plugin| plugin.internal_on_define_method(self, definition) }
      end

      # Reference indexing

      sig { params(name: String, node: Prism::Node).void }
      def reference_constant(name, node)
        @index.reference(Reference.new(name: name, kind: Reference::Kind::Constant, location: node_location(node)))
      end

      sig { params(name: String, node: Prism::Node).void }
      def reference_method(name, node)
        @index.reference(Reference.new(name: name, kind: Reference::Kind::Method, location: node_location(node)))
      end

      # Context

      sig { returns(Prism::Node) }
      def current_node
        T.must(@nodes_nesting.last)
      end

      sig { type_parameters(:N).params(type: T::Class[T.type_parameter(:N)]).returns(T.nilable(T.type_parameter(:N))) }
      def nesting_node(type)
        @nodes_nesting.reverse_each do |node|
          return T.unsafe(node) if node.is_a?(type)
        end

        nil
      end

      sig { returns(T.nilable(Prism::ClassNode)) }
      def nesting_class
        nesting_node(Prism::ClassNode)
      end

      sig { returns(T.nilable(Prism::BlockNode)) }
      def nesting_block
        nesting_node(Prism::BlockNode)
      end

      sig { returns(T.nilable(Prism::CallNode)) }
      def nesting_call
        nesting_node(Prism::CallNode)
      end

      sig { returns(T.nilable(String)) }
      def nesting_class_name
        nesting_class = self.nesting_class
        return unless nesting_class

        nesting_class.name.to_s
      end

      sig { returns(T.nilable(String)) }
      def nesting_class_superclass_name
        nesting_class_superclass = nesting_class&.superclass
        return unless nesting_class_superclass

        nesting_class_superclass.slice.delete_prefix("::")
      end

      sig { returns(T.nilable(String)) }
      def last_sig
        previous_call = @previous_node
        return unless previous_call.is_a?(Prism::CallNode)
        return unless previous_call.name == :sig

        previous_call.slice
      end

      # Node utils

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@path, node.location)
      end
    end
  end
end
