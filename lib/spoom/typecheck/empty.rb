# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    class Empty < Visitor
      extend T::Sig

      sig { void }
      def initialize
        super()

        @nodes = T.let(0, Integer)
      end

      sig { override.params(node: T.nilable(Prism::Node)).void }
      def visit(node)
        return unless node

        @nodes += 1
        super
      end
    end
  end
end
