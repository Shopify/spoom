# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Parse
    class FindNodeAtLocationTest < Minitest::Test
      extend T::Sig

      include Spoom::TestHelper

      def test_1
        node = parse_ruby(<<~RB)
          class Foo
            class Bar; end
          end
        RB

        assert_nil(find(node, 0, 0, 0, 0))

        assert_equal(<<~RB.strip, find(node, 1, 0, 3, 3))
          class Foo
            class Bar; end
          end
        RB

        assert_equal(<<~RB.strip, find(node, 1, 0, 1, 1))
          class Foo
            class Bar; end
          end
        RB

        assert_equal(<<~RB.strip, find(node, 1, 6, 1, 6))
          Foo
        RB

        assert_equal(<<~RB.strip, find(node, 2, 3, 2, 6))
          class Bar; end
        RB

        assert_equal(<<~RB.strip, find(node, 2, 8, 2, 10))
          Bar
        RB
      end

      private

      sig { params(code: String).returns(Prism::Node) }
      def parse_ruby(code)
        Spoom.parse_ruby(code, file: "-")
      end

      sig do
        params(
          node: Prism::Node,
          start_line: Integer,
          start_column: Integer,
          end_line: Integer,
          end_column: Integer,
        ).returns(T.nilable(String))
      end
      def find(node, start_line, start_column, end_line, end_column)
        location = Location.new(
          "-",
          start_line: start_line,
          start_column: start_column,
          end_line: end_line,
          end_column: end_column,
        )
        Spoom::Parse::FindNodeAtLocation.find(node, location)&.slice
      end
    end
  end
end
