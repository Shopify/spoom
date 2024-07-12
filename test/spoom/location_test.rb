# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class LocationTest < Minitest::Test
      def test_from_string
        location = Location.from_string("foo.rb:1:2-3:4")
        assert_equal("foo.rb", location.file)
        assert_equal(1, location.start_line)
        assert_equal(2, location.start_column)
        assert_equal(3, location.end_line)
        assert_equal(4, location.end_column)
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

        assert_raises(Location::LocationError) do
          Location.from_string("foo.rb")
        end
      end

      def test_include
        location1 = Location.new("foo.rb", 1, 2, 3, 4)
        location2 = Location.new("foo.rb", 1, 2, 3, 4)
        assert(location1.include?(location2))

        location3 = Location.new("foo.rb", 1, 2, 3, 5)
        refute(location1.include?(location3))
        assert(location3.include?(location1))

        location4 = Location.new("foo.rb", 1, 2, 4, 4)
        refute(location1.include?(location4))
        assert(location4.include?(location1))

        location5 = Location.new("foo.rb", 1, 3, 3, 4)
        assert(location1.include?(location5))
        refute(location5.include?(location1))

        location6 = Location.new("foo.rb", 2, 2, 3, 4)
        assert(location1.include?(location6))
        refute(location6.include?(location1))

        location7 = Location.new("bar.rb", 1, 2, 3, 4)
        refute(location1.include?(location7))
        refute(location7.include?(location1))
      end

      def test_comparison
        location1 = Location.new("foo.rb", 1, 2, 3, 4)
        location2 = Location.new("foo.rb", 1, 2, 3, 4)
        assert_equal(0, location1 <=> location2)

        location3 = Location.new("foo.rb", 1, 2, 3, 5)
        assert_equal(-1, location1 <=> location3)

        location4 = Location.new("foo.rb", 1, 2, 4, 4)
        assert_equal(-1, location1 <=> location4)

        location5 = Location.new("foo.rb", 1, 3, 3, 4)
        assert_equal(-1, location1 <=> location5)

        location6 = Location.new("foo.rb", 11, 2, 3, 4)
        assert_equal(-1, location1 <=> location6)

        location7 = Location.new("bar.rb", 1, 2, 3, 4)
        assert_equal(1, location1 <=> location7)

        not_a_location = 42
        assert_nil(location1 <=> not_a_location)
      end

      def test_to_s
        location = Location.new("foo.rb", 1, 2, 3, 4)
        assert_equal("foo.rb:1:2-3:4", location.to_s)
      end
    end
  end
end
