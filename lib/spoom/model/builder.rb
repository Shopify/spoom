# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class Builder < SyntaxTree::Visitor
      extend T::Sig

      sig { params(model: Model, file: String, source: String).void }
      def initialize(model, file, source)
        super()

        @model = model
        @file = file
        @source = source
        @namespace = T.let([], T::Array[String])
        root = T.let(Class.new(Location.none, "<root>"), Class)
        @scopes = T.let([root], T::Array[Scope])
      end

      sig { override.params(node: SyntaxTree::ClassDeclaration).void }
      def visit_class(node)
        @namespace << node_string(node.constant)

        loc = node_loc(node)
        superclass = node.superclass
        superclass_ref = Ref.new(node_string(superclass)) if superclass
        klass = Class.new(loc, current_namespace, superclass: superclass_ref)
        @model.add_class(klass)
        @scopes << klass
        super
        @scopes.pop
        @namespace.pop
      end

      sig { override.params(node: SyntaxTree::ModuleDeclaration).void }
      def visit_module(node)
        @namespace << node_string(node.constant)
        loc = node_loc(node)
        mod = Module.new(loc, current_namespace)
        @model.add_module(mod)
        @scopes << mod
        super
        @scopes.pop
        @namespace.pop
      end

      sig { override.params(node: SyntaxTree::DefNode).void }
      def visit_def(node)
        loc = node_loc(node)
        current_scope.defs << Method.new(loc, node_string(node.name))
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

      sig { override.params(node: SyntaxTree::VCall).void }
      def visit_vcall(node)
        visit_send(Send.new(node: node, name: node_string(node.value)))
      end

      private

      sig { params(send: Send).void }
      def visit_send(send)
        case send.name
        when "attr_reader", "attr_writer", "attr_accessor"
          send.args.each do |arg|
            loc = node_loc(arg)
            name = node_string(arg)
            current_scope.attrs << Attr.new(loc, send.name, name)
          end
        when "const", "prop"
          loc = node_loc(send.node)
          name = node_string(T.must(send.args[0]))
          type = node_string(T.must(send.args[1]))
          read_only = send.name == "const"
          has_default = send.args.any? do |arg|
            arg.is_a?(SyntaxTree::BareAssocHash) && node_string(arg) =~ /default:/
          end
          current_scope.props << Prop.new(loc, name, type, read_only: read_only, has_default: has_default)
        when "include", "prepend"
          send.args.each do |arg|
            current_scope.includes << Ref.new(node_string(arg))
          end
        end
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

      sig { returns(String) }
      def current_namespace
        @namespace.join("::")
      end

      sig { returns(Scope) }
      def current_scope
        T.must(@scopes.last)
      end

      sig { params(node: SyntaxTree::Node).returns(Location) }
      def node_loc(node)
        Location.from_syntax_tree(@file, node.location)
      end

      sig { params(node: T.any(::Symbol, SyntaxTree::Node)).returns(String) }
      def node_string(node)
        case node
        when ::Symbol
          node.to_s
        else
          T.must(@source[node.location.start_char...node.location.end_char])
        end
      end
    end

    class Send < T::Struct
      extend T::Sig

      const :node, SyntaxTree::Node
      const :name, String
      const :recv, T.nilable(SyntaxTree::Node), default: nil
      const :args, T::Array[SyntaxTree::Node], default: []
      const :block, T.nilable(SyntaxTree::Node), default: nil
    end

    class << self
      extend T::Sig

      sig { params(file: String).returns(Model) }
      def from_file(file)
        model = Model.new
        source = File.read(file)
        indexer = Builder.new(model, file, source)
        tree = SyntaxTree.parse(source)
        indexer.visit(tree)
        model
      rescue SyntaxTree::Parser::ParseError => e
        raise "Error parsing `#{file}`: #{e.message} at line #{e.lineno}"
      end
    end
  end
end
