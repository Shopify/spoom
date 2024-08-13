# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class LocationTest < Minitest::Test
      def test_from_string
        location1 = Location.from_string("foo.rb:1:2-3:4")
        assert_equal("foo.rb", location1.file)
        assert_equal(1, location1.start_line)
        assert_equal(2, location1.start_column)
        assert_equal(3, location1.end_line)
        assert_equal(4, location1.end_column)

        location2 = Location.from_string("foo.rb:1-3")
        assert_equal(1, location2.start_line)
        assert_equal(3, location2.end_line)
        assert_nil(location2.start_column)
        assert_nil(location2.end_column)

        location3 = Location.from_string("foo.rb")
        assert_equal("foo.rb", location3.file)
        assert_nil(location3.start_line)
        assert_nil(location3.start_column)
        assert_nil(location3.end_line)
        assert_nil(location3.end_column)
      end

      def test_raises_if_location_string_has_missing_components
        assert_raises(Location::LocationError) do
          Location.from_string("foo.rb:1:2-3")
        end

        assert_raises(Location::LocationError) do
          Location.from_string("foo.rb:1:2")
        end

        assert_raises(Location::LocationError) do
          Location.from_string("foo.rb:1")
        end
      end

      def test_raises_if_initialize_has_missing_attributes
        assert_raises(Location::LocationError) do
          Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3)
        end

        assert_raises(Location::LocationError) do
          Location.new("foo.rb", start_line: 1, start_column: 2, end_column: 3)
        end

        assert_raises(Location::LocationError) do
          Location.new("foo.rb", start_line: 1, end_column: 2, end_line: 3)
        end

        assert_raises(Location::LocationError) do
          Location.new("foo.rb", start_column: 1, end_column: 2, end_line: 3)
        end

        assert_raises(Location::LocationError) do
          Location.new("foo.rb", start_line: 1, start_column: 2)
        end

        assert_raises(Location::LocationError) do
          Location.new("foo.rb", start_line: 1)
        end
      end

      def test_include
        location1 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 4)
        location2 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 4)
        assert(location1.include?(location2))

        location3 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 5)
        refute(location1.include?(location3))
        assert(location3.include?(location1))

        location4 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 4, end_column: 4)
        refute(location1.include?(location4))
        assert(location4.include?(location1))

        location5 = Location.new("foo.rb", start_line: 1, start_column: 3, end_line: 3, end_column: 4)
        assert(location1.include?(location5))
        refute(location5.include?(location1))

        location6 = Location.new("foo.rb", start_line: 2, start_column: 2, end_line: 3, end_column: 4)
        assert(location1.include?(location6))
        refute(location6.include?(location1))

        location7 = Location.new("bar.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 4)
        refute(location1.include?(location7))
        refute(location7.include?(location1))

        location8 = Location.new("foo.rb")
        location9 = Location.new("foo.rb")
        assert(location8.include?(location9))
        assert(location9.include?(location8))

        assert(location8.include?(location1))
        refute(location1.include?(location8))

        location10 = Location.new("foo.rb", start_line: 1, end_line: 3)
        assert(location10.include?(location1))
        refute(location1.include?(location10))
      end

      def test_comparison
        location1 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 4)
        location2 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 4)
        assert_equal(0, location1 <=> location2)

        location3 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 5)
        assert_equal(-1, location1 <=> location3)

        location4 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 4, end_column: 4)
        assert_equal(-1, location1 <=> location4)

        location5 = Location.new("foo.rb", start_line: 1, start_column: 3, end_line: 3, end_column: 4)
        assert_equal(-1, location1 <=> location5)

        location6 = Location.new("foo.rb", start_line: 11, start_column: 2, end_line: 3, end_column: 4)
        assert_equal(-1, location1 <=> location6)

        location7 = Location.new("bar.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 4)
        assert_equal(1, location1 <=> location7)

        not_a_location = 42
        assert_nil(location1 <=> not_a_location)

        location8 = Location.new("foo.rb")
        location9 = Location.new("foo.rb")
        assert_equal(0, location8 <=> location9)

        location10 = Location.new("foo.rb", start_line: 1, end_line: 3)
        assert_equal(-1, location8 <=> location10)
      end

      def test_snippet
        context = Context.mktmp!

        foo_rb = <<~RB
          def foo; end
          def bar; end
          def baz; end
        RB
        context.write!("foo.rb", foo_rb)
        foo_path = context.absolute_path_to("foo.rb")

        location1 = Location.new(foo_path)
        assert_equal(foo_rb, location1.snippet)

        assert_raises(Location::LocationError) do
          location1.snippet(lines_around: -1)
        end

        location2 = Location.new(foo_path, start_line: 1, end_line: 3)
        assert_equal(foo_rb, location2.snippet)

        location3 = Location.new(foo_path, start_line: 1, end_line: 1)
        assert_equal(<<~RB, location3.snippet)
          def foo; end
        RB

        location4 = Location.new(foo_path, start_line: 2, end_line: 2)
        assert_equal(<<~RB, location4.snippet)
          def bar; end
        RB

        location5 = Location.new(foo_path, start_line: 3, end_line: 3)
        assert_equal(<<~RB, location5.snippet)
          def baz; end
        RB

        location6 = Location.new(foo_path, start_line: 2, end_line: 3)
        assert_equal(<<~RB, location6.snippet)
          def bar; end
          def baz; end
        RB
      end

      def test_snippet_lines_around
        context = Context.mktmp!

        foo_rb = <<~RB
          def foo; end
          def bar; end
          def baz; end
          def qux; end
          def quux; end
          def quuz; end
        RB
        context.write!("foo.rb", foo_rb)
        foo_path = context.absolute_path_to("foo.rb")

        location1 = Location.new(foo_path, start_line: 1, end_line: 6)
        assert_equal(foo_rb, location1.snippet(lines_around: 0))

        location2 = Location.new(foo_path, start_line: 1, end_line: 6)
        assert_equal(foo_rb, location2.snippet(lines_around: 1))

        location4 = Location.new(foo_path, start_line: 3, end_line: 3)
        assert_equal(foo_rb, location4.snippet(lines_around: 20))

        location5 = Location.new(foo_path, start_line: 3, end_line: 4)
        assert_equal(<<~RB, location5.snippet(lines_around: 1))
          def bar; end
          def baz; end
          def qux; end
          def quux; end
        RB
      end

      def test_to_s
        location1 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 4)
        assert_equal("foo.rb:1:2-3:4", location1.to_s)

        location2 = Location.new("foo.rb", start_line: 1, end_line: 3)
        assert_equal("foo.rb:1-3", location2.to_s)

        location3 = Location.new("foo.rb")
        assert_equal("foo.rb", location3.to_s)
      end
    end
  end
end
