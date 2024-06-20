# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    # Visit a file to collect all the references to constants and methods
    class ReferencesVisitor < Visitor
      extend T::Sig

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
        visit(node.receiver)

        name = node.name.to_s
        reference_method(name, node)

        case name
        when "<", ">", "<=", ">="
          # For comparison operators, we also reference the `<=>` method
          reference_method("<=>", node)
        end

        visit(node.arguments)
        visit(node.block)
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

      sig { override.params(node: Prism::ConstantPathNode).void }
      def visit_constant_path_node(node)
        visit(node.parent)
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
        reference_method("#{node.name}=", node)
        visit(node.value)
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

      private

      sig { params(name: String, node: Prism::Node).void }
      def reference_constant(name, node)
        @references << Reference.constant(name, node_location(node))
      end

      sig { params(name: String, node: Prism::Node).void }
      def reference_method(name, node)
        @references << Reference.method(name, node_location(node))
      end

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@file, node.location)
      end
    end
  end
end
