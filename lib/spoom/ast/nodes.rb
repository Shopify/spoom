# typed: strict
# frozen_string_literal: true

module Spoom
  module AST
    class Node
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(T.nilable(Location)) }
      attr_reader :location

      sig { params(location: Location).void }
      def initialize(location)
        @location = location
      end
    end

    class Tree < Node
      sig { returns(T::Array[Node]) }
      attr_reader :nodes

      sig { params(location: Location, nodes: T::Array[Node]).void }
      def initialize(location, nodes: [])
        super(location)

        @nodes = nodes
      end
    end

    class ProgramNode < Tree
    end

    class StatementsNode < Node
    end

    class IfNode < Node
      sig { returns(Node) }
      attr_reader :predicate

      sig { returns(StatementsNode) }
      attr_reader :if_body

      sig { returns(StatementsNode) }
      attr_reader :else_body

      sig { params(location: Location, predicate: Node, if_body: StatementsNode, else_body: StatementsNode).void }
      def initialize(
        location,
        predicate,
        if_body: StatementsNode.new(location),
        else_body: StatementsNode.new(location)
      )
        super(location)
        @predicate = predicate
        @if_body = if_body
        @else_body = else_body
      end
    end

    class CallNode < Node
      sig { returns(Symbol) }
      attr_reader :method_name

      sig { returns(T::Array[Node]) }
      attr_reader :arguments

      sig { params(location: Location, method_name: Symbol, arguments: T::Array[Node]).void }
      def initialize(location, method_name, arguments)
        super(location)

        @method_name = method_name
        @arguments = arguments
      end
    end

    class TODONode < Node
      sig { returns(String) }
      attr_reader :raw

      sig { params(location: Location, raw: String).void }
      def initialize(location, raw)
        super(location)
        @raw = raw
      end
    end
  end
end
