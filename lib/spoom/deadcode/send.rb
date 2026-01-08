# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    # An abstraction to simplify handling of Prism::CallNode nodes.
    class Send
      #: Prism::CallNode
      attr_reader :node

      #: String
      attr_reader :name

      #: Prism::Node?
      attr_reader :recv

      #: Array[Prism::Node]
      attr_reader :args

      #: Prism::Node?
      attr_reader :block

      #: Location
      attr_reader :location

      #: (
      #|   node: Prism::CallNode,
      #|   name: String,
      #|   location: Location,
      #|   ?recv: Prism::Node?,
      #|   ?args: Array[Prism::Node],
      #|   ?block: Prism::Node?
      #| ) -> void
      def initialize(node:, name:, location:, recv: nil, args: [], block: nil)
        @node = node
        @name = name
        @recv = recv
        @args = args
        @block = block
        @location = location
      end

      #: [T] (Class[T] arg_type) { (T arg) -> void } -> void
      def each_arg(arg_type, &block)
        args.each do |arg|
          yield(T.unsafe(arg)) if arg.is_a?(arg_type)
        end
      end

      #: { (Prism::Node key, Prism::Node? value) -> void } -> void
      def each_arg_assoc(&block)
        args.each do |arg|
          next unless arg.is_a?(Prism::KeywordHashNode) || arg.is_a?(Prism::HashNode)

          arg.elements.each do |assoc|
            yield(assoc.key, assoc.value) if assoc.is_a?(Prism::AssocNode)
          end
        end
      end
    end
  end
end
