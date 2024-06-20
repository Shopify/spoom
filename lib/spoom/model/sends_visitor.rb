# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class SendsVisitor < Visitor
      module Listener
        extend T::Sig
        extend T::Helpers

        interface!

        sig { abstract.params(send: Send).void }
        def on_send(send); end
      end

      sig { returns(T::Array[Send]) }
      attr_reader :sends

      sig { params(file: String, listeners: T::Array[Listener]).void }
      def initialize(file, listeners)
        super()

        @file = file
        @listeners = listeners
        @sends = T.let([], T::Array[Send])
      end

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        visit(node.receiver)

        @sends << Send.new(
          node: node,
          name: node.name.to_s,
          recv: node.receiver,
          args: node.arguments&.arguments || [],
          block: node.block,
          location: node_location(node),
        )

        # @listeners.each { |listener| listener.on_send(send) }

        visit(node.arguments)
        visit(node.block)
      end

      private

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@file, node.location)
      end
    end
  end
end
