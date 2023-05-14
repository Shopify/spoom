# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class Indexer < SyntaxTree::Visitor
      extend T::Sig

      sig { params(index: Index).void }
      def initialize(index)
        super()

        @index = index
        @file = T.let(nil, T.nilable(String))
      end

      sig { params(path: String).void }
      def index_file(path)
        @file = path
        ast = SyntaxTree.parse_file(path)
        visit(ast)
        @file = nil
      end

      sig { params(ruby: String, path: String).void }
      def index_string(ruby, path: "-")
        @file = path
        ast = SyntaxTree.parse(ruby)
        visit(ast)
        @file = nil
      end

      sig { params(node: SyntaxTree::ClassDeclaration).void }
      def visit_class(node)
        location = location_from_node(node)
        @index.add_name(node.constant.constant.value, location)

        super
      end

      private

      sig { params(node: SyntaxTree::Node).returns(Location) }
      def location_from_node(node)
        location = node.location
        Location.new(T.must(@file), location.start_line, location.start_column, location.end_line, location.end_column)
      end
    end
  end
end
