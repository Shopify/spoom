# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class Reference < T::Struct
      extend T::Sig

      class Kind < T::Enum
        enums do
          Constant = new
          Method = new
        end
      end

      const :kind, Kind
      const :name, String
      const :location, Spoom::Location

      # Kind

      sig { returns(T::Boolean) }
      def constant?
        kind == Kind::Constant
      end

      sig { returns(T::Boolean) }
      def method?
        kind == Kind::Method
      end
    end

    class ReferencesVisitor < Visitor
      extend T::Sig

      class Send < T::Struct
        extend T::Sig

        const :node, Prism::CallNode
        const :name, String
        const :recv, T.nilable(Prism::Node), default: nil
        const :args, T::Array[Prism::Node], default: []
        const :block, T.nilable(Prism::Node), default: nil
      end

      sig { returns(T::Array[Reference]) }
      attr_reader :references

      sig { params(file: String).void }
      def initialize(file)
        super()

        @file = file
        @references = T.let([], T::Array[Reference])
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
        visit(node.superclass) if node.superclass
        visit(node.body)
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

      sig { override.params(node: Prism::ConstantPathWriteNode).void }
      def visit_constant_path_write_node(node)
        parent = node.target.parent
        visit(parent) if parent
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
        visit(node.body)
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

        reference_method(send.name, send.node)

        case send.name
        when "<", ">", "<=", ">="
          # For comparison operators, we also reference the `<=>` method
          reference_method("<=>", send.node)
        end

        visit_all(send.args)
        visit(send.block)
      end

      private

      sig { params(name: String, node: Prism::Node).void }
      def reference_constant(name, node)
        @references << Reference.new(name: name, kind: Reference::Kind::Constant, location: node_location(node))
      end

      sig { params(name: String, node: Prism::Node).void }
      def reference_method(name, node)
        @references << Reference.new(name: name, kind: Reference::Kind::Method, location: node_location(node))
      end

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@file, node.location)
      end
    end
  end
end
