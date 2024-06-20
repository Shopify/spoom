# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Indexer < Visitor
      extend T::Sig

      sig { returns(String) }
      attr_reader :path

      sig { returns(Index) }
      attr_reader :index

      sig { params(path: String, index: Index, plugins: T::Array[Plugins::Base]).void }
      def initialize(path, index, plugins: [])
        super()

        @path = path
        @index = index
        @plugins = plugins
      end

      # Visit

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        visit(node.receiver)

        send = Send.new(
          node: node,
          name: node.name.to_s,
          recv: node.receiver,
          args: node.arguments&.arguments || [],
          block: node.block,
          location: Location.from_prism(@path, node.location),
        )

        @plugins.each do |plugin|
          plugin.on_send(send)
        end

        visit(node.arguments)
        visit(send.block)
      end
    end
  end
end
