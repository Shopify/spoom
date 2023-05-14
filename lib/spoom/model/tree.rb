# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class Node
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(T.nilable(Location)) }
      attr_reader :location

      sig { params(location: T.nilable(Location)).void }
      def initialize(location: nil)
        @location = location
      end
    end

    class Tree < Node
      extend T::Sig

      sig { returns(T::Array[Node]) }
      attr_reader :nodes

      sig { params(location: T.nilable(Location)).void }
      def initialize(location: nil)
        super(location: location)

        @nodes = T.let([], T::Array[Node])
      end

      sig { params(node: Node).void }
      def <<(node)
        @nodes << node
      end
    end

    class Class < Tree
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String, location: T.nilable(Location)).void }
      def initialize(name, location: nil)
        super(location: location)

        @name = name
      end
    end
  end
end
