# typed: strict
# frozen_string_literal: true

module Spoom
  module Stubs
    class Call
      extend T::Sig

      sig { returns(Spoom::Location) }
      attr_reader :location

      sig { returns(T.nilable(Prism::Node)) }
      attr_reader :receiver_node

      sig { returns(T.nilable(Prism::Node)) }
      attr_reader :expects_node

      sig { returns(T::Array[Prism::Node]) }
      attr_reader :with_nodes

      sig { returns(T.nilable(Prism::Node)) }
      attr_reader :returns_node

      sig do
        params(
          location: Spoom::Location,
          receiver_node: T.nilable(Prism::Node),
          expects_node: T.nilable(Prism::Node),
          with_nodes: T::Array[Prism::Node],
          returns_node: T.nilable(Prism::Node),
        ).void
      end
      def initialize(location:, receiver_node:, expects_node:, with_nodes:, returns_node:)
        @location = location
        @receiver_node = receiver_node
        @expects_node = expects_node
        @with_nodes = with_nodes
        @returns_node = returns_node
      end

      sig { returns(String) }
      def to_s
        <<~STR
          #{@location}
            #{@receiver_node&.slice}
              .#{@expects_node&.slice}
              .with(#{@with_nodes.map(&:to_s).join(", ")})
              .returns(#{@returns_node&.slice})
        STR
      end
    end
  end
end
