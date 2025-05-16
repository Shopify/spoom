# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Source
    class RewriterTest < Minitest::Test
      def test_rewriter_no_edits
        string = "Hello, world!"

        rewritten = rewrite(string) do |rewriter|
          # no edits
        end

        assert_equal(string, rewritten)
      end

      def test_rewriter_insert_raises_if_incorrect_position
        assert_raises(PositionError) do
          rewrite("") do |rewriter|
            rewriter << Insert.new(-1, "")
          end
        end

        assert_raises(PositionError) do
          rewrite("") do |rewriter|
            rewriter << Insert.new(1, "")
          end
        end
      end

      def test_rewriter_insert_in_empty_string
        rewritten = rewrite("") do |rewriter|
          rewriter << Insert.new(0, "Hello, world!")
        end

        assert_equal("Hello, world!", rewritten)
      end

      def test_rewriter_insert_at_beginning
        rewritten = rewrite("world!") do |rewriter|
          rewriter << Insert.new(0, "Hello, ")
        end

        assert_equal("Hello, world!", rewritten)
      end

      def test_rewriter_insert_at_end
        rewritten = rewrite("Hello, ") do |rewriter|
          rewriter << Insert.new(7, "world!")
        end

        assert_equal("Hello, world!", rewritten)
      end

      def test_rewriter_insert_in_middle
        rewritten = rewrite("Hello, world!") do |rewriter|
          rewriter << Insert.new(7, "beautiful ")
        end

        assert_equal("Hello, beautiful world!", rewritten)
      end

      def test_rewriter_insert_multiple_times_at_the_same_position
        rewritten = rewrite("") do |rewriter|
          rewriter << Insert.new(0, "Hello,")
          rewriter << Insert.new(0, " world!")
        end

        assert_equal("Hello, world!", rewritten)
      end

      def test_rewriter_replace_raises_if_incorrect_position
        assert_raises(PositionError) do
          rewrite("") do |rewriter|
            rewriter << Replace.new(-1, 0, "")
          end
        end

        assert_raises(PositionError) do
          rewrite("") do |rewriter|
            rewriter << Replace.new(0, 1, "")
          end
        end

        assert_raises(PositionError) do
          rewrite("foo") do |rewriter|
            rewriter << Replace.new(1, 0, "")
          end
        end
      end

      def test_rewriter_replace
        rewritten = rewrite("Hello, world!") do |rewriter|
          rewriter << Replace.new(7, 11, "universe")
        end

        assert_equal("Hello, universe!", rewritten)
      end

      def test_rewriter_replace_entire_string
        rewritten = rewrite("Hello, world!") do |rewriter|
          rewriter << Replace.new(0, 12, "Goodbye, universe!")
        end

        assert_equal("Goodbye, universe!", rewritten)
      end

      def test_rewriter_replace_multiple_times_at_the_same_position
        rewritten = rewrite("Hello, world!") do |rewriter|
          rewriter << Replace.new(7, 11, "thing") # applied last
          rewriter << Replace.new(7, 11, "WORLD") # applied first
        end

        # This is expected behavior, because the edits are applied from bottom to top in reverse order.
        # While strange for replacements, it's the best expected behavior for insertions.
        assert_equal("Hello, thing!", rewritten)
      end

      def test_rewriter_replace_position_is_inclusive
        rewritten = rewrite("Hello") do |rewriter|
          rewriter << Replace.new(0, 0, "A")
          rewriter << Replace.new(1, 1, "B")
          rewriter << Replace.new(2, 2, "C")
          rewriter << Replace.new(3, 3, "D")
          rewriter << Replace.new(4, 4, "E")
        end

        assert_equal("ABCDE", rewritten)
      end

      def test_rewriter_replace_with_longer_string
        rewritten = rewrite("Hello") do |rewriter|
          rewriter << Replace.new(0, 4, "Bonjour")
        end

        assert_equal("Bonjour", rewritten)
      end

      def test_rewriter_replace_with_shorter_string
        rewritten = rewrite("Hello, world!") do |rewriter|
          rewriter << Replace.new(0, 12, "Bonjour")
        end

        assert_equal("Bonjour", rewritten)
      end

      def test_rewriter_delete_raises_if_incorrect_position
        assert_raises(PositionError) do
          rewrite("") do |rewriter|
            rewriter << Delete.new(-1, 0)
          end
        end

        assert_raises(PositionError) do
          rewrite("") do |rewriter|
            rewriter << Delete.new(0, 1)
          end
        end

        assert_raises(PositionError) do
          rewrite("foo") do |rewriter|
            rewriter << Delete.new(1, 0)
          end
        end
      end

      def test_rewriter_delete
        rewritten = rewrite("hello world") do |rewriter|
          rewriter << Delete.new(0, 1)
          rewriter << Delete.new(6, 10)
          rewriter << Delete.new(4, 5)
        end

        assert_equal("ll", rewritten)
      end

      def test_rewriter_operations_are_applied_in_reverse_position_order
        rewritten = rewrite("hello world") do |rewriter|
          rewriter << Replace.new(0, 4, "goodbye")
          rewriter << Insert.new(5, " cruel")
          rewriter << Replace.new(6, 11, "universe")
        end

        assert_equal("goodbye cruel universe", rewritten)

        # this is the same as:

        rewritten = rewrite("hello world") do |rewriter|
          rewriter << Replace.new(6, 11, "universe")
          rewriter << Insert.new(5, " cruel")
          rewriter << Replace.new(0, 4, "goodbye")
        end

        assert_equal("goodbye cruel universe", rewritten)
      end

      private

      #: (String) { (Rewriter) -> void } -> String
      def rewrite(string, &block)
        bytes = string.bytes
        rewriter = Rewriter.new
        yield(rewriter)
        rewriter.rewrite!(bytes)
        bytes.pack("C*")
      end
    end
  end
end
