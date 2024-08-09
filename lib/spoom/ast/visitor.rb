# typed: true
# frozen_string_literal: true

module Spoom
  module AST
    class Visitor
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { params(node: Node).void }
      def visit(node)
        case node
        when TODONode
          visit_todo_node(node)
        when IfNode
          visit_if_node(node)
        else
          raise "Unknown node: #{node}"
        end
      end

      sig { params(node: IfNode).void }
      def visit_if_node(node)
        visit(node.predicate)
        visit(node.if_body)
        visit(node.else_body)
      end

      sig { params(node: TODONode).void }
      def visit_todo_node(node)
        # no-op
      end
    end
  end
end
