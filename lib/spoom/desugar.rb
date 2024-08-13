# typed: ignore
# frozen_string_literal: true

module Spoom
  class Desugar < Visitor
    extend T::Sig

    def initialize
      super()

      @nodes_stack = T.let([], T::Array[Prism::Node])
    end

    sig { override.params(node: Prism::Node).void }
    def visit(node)
      puts node
      @nodes_stack << node
      super
      @nodes_stack.pop
    end

    sig { override.params(node: Prism::UnlessNode).void }
    def visit_unless_node(node)
      replace(
        node,
        Prism::IfNode.new(
          node.send(:source),
          node.then_keyword_loc,
          node.predicate,
          nil,
          make_statements_node(*T.unsafe(node.consequent)), # invert with statements
          node.statements, # invert with consequent
          node.end_keyword_loc,
          node.location,
        ),
      )
    end

    private

    sig { params(statements: Prism::Node).returns(Prism::StatementsNode) }
    def make_statements_node(*statements)
      Prism::StatementsNode.new(
        T.unsafe(nil),
        statements,
        no_loc,
      )
    end

    sig { params(node: Prism::Node, replacement: Prism::Node).void }
    def replace(node, replacement)
      # @parent.replace_child(node, replacement)
      puts node
      puts node.slice
      puts replacement
      puts replacement.slice

      parent_node = parent_node(node)
      index = parent_node.child_nodes.index(node)
      raise unless index

      puts parent_node(node).child_nodes[index]
      puts parent_node(node).child_nodes[index] = replacement
      puts parent_node(node).child_nodes[index]
    end

    sig { params(node: Prism::Node).returns(Prism::Node) }
    def parent_node(node)
      last = @nodes_stack.last
      raise unless last
      raise unless last == node

      parent = @nodes_stack[-2]
      raise unless parent

      parent
    end

    sig { returns(Prism::Location) }
    def no_loc
      Prism::Location.new(T.unsafe(nil), 0, 0)
    end
  end
end
