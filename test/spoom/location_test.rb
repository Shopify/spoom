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
        assert_includes(location1, location2)

        location3 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 5)
        refute_includes(location1, location3)
        assert_includes(location3, location1)

        location4 = Location.new("foo.rb", start_line: 1, start_column: 2, end_line: 4, end_column: 4)
        refute_includes(location1, location4)
        assert_includes(location4, location1)

        location5 = Location.new("foo.rb", start_line: 1, start_column: 3, end_line: 3, end_column: 4)
        assert_includes(location1, location5)
        refute_includes(location5, location1)

        location6 = Location.new("foo.rb", start_line: 2, start_column: 2, end_line: 3, end_column: 4)
        assert_includes(location1, location6)
        refute_includes(location6, location1)

        location7 = Location.new("bar.rb", start_line: 1, start_column: 2, end_line: 3, end_column: 4)
        refute_includes(location1, location7)
        refute_includes(location7, location1)

        location8 = Location.new("foo.rb")
        location9 = Location.new("foo.rb")
        assert_includes(location8, location9)
        assert_includes(location9, location8)

        assert_includes(location8, location1)
        refute_includes(location1, location8)

        location10 = Location.new("foo.rb", start_line: 1, end_line: 3)
        assert_includes(location10, location1)
        refute_includes(location1, location10)
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
