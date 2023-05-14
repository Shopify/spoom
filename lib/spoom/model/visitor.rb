# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class Visitor
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { params(node: Node).void }
      def visit(node)
        node.accept(self)
      end

      sig { params(tree: Tree).void }
      def visit_tree(tree)
        tree.nodes.each { |node| visit(node) }
      end

      sig { params(klass: Class).void }
      def visit_class(klass)
        klass.nodes.each { |node| visit(node) }
      end
    end

    class Node
      extend T::Sig

      sig { abstract.params(visitor: Visitor).void }
      def accept(visitor); end
    end

    class Tree < Node
      extend T::Sig

      sig { override.params(visitor: Visitor).void }
      def accept(visitor)
        visitor.visit_tree(self)
      end
    end

    class Class < Tree
      extend T::Sig

      sig { override.params(visitor: Visitor).void }
      def accept(visitor)
        visitor.visit_class(self)
      end
    end
  end
end
