# typed: ignore
# frozen_string_literal: true

module Spoom
  module AST
    class << self
      extend T::Sig

      sig { params(node: ::Prism::Node, file: String).returns(Node) }
      def from_prism(node, file:)
        v = Prism.new(file)
        v.visit(node)
        v.node
      end
    end

    class Prism < Spoom::Visitor
      extend T::Sig

      sig { params(file: String).void }
      def initialize(file)
        super()

        @file = file
        @tree_stack = T.let([], T::Array[AST::Tree])
      end

      sig { returns(Tree) }
      def tree
        T.must(@tree_stack.first)
      end

      sig { override.params(node: ::Prism::Node).void }
      def visit_program_node(node)
        @tree_stack << ProgramNode.new(
          Location.from_prism(@file, node.location),
        )
      end

      # def visit_statements_node(node)
      #   @nodes_stack.statements
      # end

      sig { override.params(node: ::Prism::IfNode).void }
      def visit_if_node(node)
        predicate = visit(node.predicate)
        if_body = visit(node.if_body)
        else_body = visit(node.else_body)
        IfNode.new(
          Location.from_prism(@file, node.location),
          predicate,
          if_body: if_body,
          else_body: else_body,
        )
      end

      # sig { params(node: ::Prism::Node).void }
      # def visit_node(node)
      #   @nodes_stack << node
      #   super
      #   @nodes_stack.pop
      # end
    end
  end
end
