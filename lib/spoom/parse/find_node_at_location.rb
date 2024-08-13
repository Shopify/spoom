# typed: true
# frozen_string_literal: true

module Spoom
  module Parse
    class FindNodeAtLocation < Visitor
      extend T::Sig

      class << self
        extend T::Sig

        sig { params(node: Prism::Node, target_location: Location).returns(T.nilable(Prism::Node)) }
        def find(node, target_location)
          visitor = new(target_location)
          visitor.visit(node)
          visitor.nodes&.last
        end
      end

      attr_reader :nodes

      sig { params(target_location: Location).void }
      def initialize(target_location)
        super()

        @target_location = target_location
        @nodes = T.let([], T::Array[Prism::Node])
      end

      sig { override.params(node: T.nilable(Prism::Node)).void }
      def visit(node)
        return unless node

        location = Location.from_prism(@target_location.file, node.location)

        target_start_column = @target_location.start_column
        target_end_column = @target_location.end_column
        if target_start_column && target_end_column
          return unless location.include?(@target_location)
        elsif T.must(@target_location.start_line) < T.must(location.start_line) ||
            T.must(@target_location.end_line) > T.must(location.end_line)
          return
        end

        @nodes << node

        super
      end
    end
  end
end
