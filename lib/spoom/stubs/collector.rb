# typed: strict
# frozen_string_literal: true

module Spoom
  module Stubs
    class Collector < Visitor
      extend T::Sig

      sig { returns(String) }
      attr_reader :file

      sig { returns(T::Array[T.any(Prism::ClassNode, Prism::ModuleNode)]) }
      attr_reader :nesting

      sig { returns(T::Array[Call]) }
      attr_reader :stubs

      sig { params(file: String).void }
      def initialize(file)
        super()

        @file = file
        @stubs = T.let([], T::Array[Call])
        @nesting = T.let([], T::Array[T.any(Prism::ClassNode, Prism::ModuleNode)])
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        # return unless node.name.end_with?("Test")

        @nesting << node
        super
        @nesting.pop
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        @nesting << node
        super
        @nesting.pop
      end

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        # Getting inside a `test "..."` block
        return unless node.name == :test && node.arguments&.arguments&.size == 1 && node.block

        visitor = TestCaseVisitor.new(self)
        visitor.visit(node.block)
      end
    end

    class TestCaseVisitor < Visitor
      extend T::Sig

      PREDICATES = T.let([:expects, :with, :returns], T::Array[Symbol])

      sig { params(subs_visitor: Collector).void }
      def initialize(subs_visitor)
        super()

        @subs_visitor = subs_visitor
        @file = T.let(subs_visitor.file, String)
      end

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        return unless node.name == :returns

        stub_call = visit_stub_call(node)
        @subs_visitor.stubs << stub_call
      end

      private

      sig { params(node: Prism::CallNode).returns(Call) }
      def visit_stub_call(node)
        expects_node = T.let(nil, T.nilable(Prism::Node))
        returns_node = T.let(nil, T.nilable(Prism::Node))
        with_nodes = T.let([], T::Array[Prism::Node])

        receiver = T.let(node, T.nilable(Prism::Node))
        while receiver.is_a?(Prism::CallNode)
          case receiver.name
          when :returns
            returns_node = receiver.arguments&.arguments&.first
          when :with
            with_nodes = receiver.arguments&.arguments || []
          when :expects, :stubs
            expects_node = receiver.arguments&.arguments&.first
          end

          receiver = receiver.receiver
        end

        Call.new(
          location: Spoom::Location.new(
            @file,
            start_line: node.location.start_line,
            start_column: node.location.start_column,
            end_line: node.location.end_line,
            end_column: node.location.end_column,
          ),
          nesting: @subs_visitor.nesting.dup,
          receiver_node: receiver,
          expects_node: expects_node,
          with_nodes: with_nodes,
          returns_node: returns_node,
        )
      end

      sig { params(node: Prism::CallNode).returns(T.nilable(Prism::Node)) }
      def get_receiver(node)
        node = T.let(node.receiver, T.nilable(Prism::Node))
        node = node.receiver while node.is_a?(Prism::CallNode) && node.receiver
        node
      end

      sig { params(location: Prism::Location).returns(String) }
      def loc_string(location)
        "#{@file}:#{location.start_line}"
      end
    end
  end
end
