# typed: true
# frozen_string_literal: true

require "test_helper"
require "stringio"

module Spoom
  module LSP
    class StructuresTest < Minitest::Test
      class CollidingString < String
        #: -> Integer
        def hash = 0
      end

      def test_symbol_printer_deduplicates_structurally_equal_symbols
        output = StringIO.new
        printer = SymbolPrinter.new(out: output, colors: false)

        printer.print_objects([symbol("Repeated"), symbol("Repeated")])

        assert_equal(<<~OUTPUT, output.string)
          class Repeated (1:2-3:4)
            def Child (5:6-7:8)
        OUTPUT
      end

      def test_symbol_printer_keeps_distinct_symbols_with_colliding_hashes
        first_name = CollidingString.new("First")
        second_name = CollidingString.new("Second")
        assert_equal(first_name.hash, second_name.hash)

        output = StringIO.new
        printer = SymbolPrinter.new(out: output, colors: false)

        printer.print_objects([symbol(first_name), symbol(second_name)])

        assert_equal(<<~OUTPUT, output.string)
          class First (1:2-3:4)
            def Child (5:6-7:8)
          class Second (1:2-3:4)
        OUTPUT
      end

      private

      #: (String name) -> DocumentSymbol
      def symbol(name)
        DocumentSymbol.new(
          name: name,
          detail: "details",
          kind: 5,
          location: Location.new(uri: "file:///example.rb", range: range(9)),
          range: range(1),
          children: [
            DocumentSymbol.new(name: "Child", kind: 6, range: range(5), children: []),
          ],
        )
      end

      #: (Integer line) -> Range
      def range(line)
        Range.new(
          start_pos: Position.new(line: line, char: line + 1),
          end_pos: Position.new(line: line + 2, char: line + 3),
        )
      end
    end
  end
end
