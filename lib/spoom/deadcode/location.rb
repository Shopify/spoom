# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Location
      extend T::Sig

      include Comparable

      class LocationError < Spoom::Error; end

      class << self
        extend T::Sig

        sig { params(location_string: String).returns(Location) }
        def from_string(location_string)
          file, rest = location_string.split(":", 2)
          raise LocationError, "Invalid location string: #{location_string}" unless file && rest

          start_line, rest = rest.split(":", 2)
          raise LocationError, "Invalid location string: #{location_string}" unless start_line && rest

          start_column, rest = rest.split("-", 2)
          raise LocationError, "Invalid location string: #{location_string}" unless start_column && rest

          end_line, end_column = rest.split(":", 2)
          raise LocationError, "Invalid location string: #{location_string}" unless end_line && end_column

          new(file, start_line.to_i, start_column.to_i, end_line.to_i, end_column.to_i)
        end

        sig { params(file: String, location: SyntaxTree::Location).returns(Location) }
        def from_syntax_tree(file, location)
          new(file, location.start_line, location.start_column, location.end_line, location.end_column)
        end
      end

      sig { returns(String) }
      attr_reader :file

      sig { returns(Integer) }
      attr_reader :start_line, :start_column, :end_line, :end_column

      sig do
        params(
          file: String,
          start_line: Integer,
          start_column: Integer,
          end_line: Integer,
          end_column: Integer,
        ).void
      end
      def initialize(file, start_line, start_column, end_line, end_column)
        @file = file
        @start_line = start_line
        @start_column = start_column
        @end_line = end_line
        @end_column = end_column
      end

      sig { params(other: Location).returns(T::Boolean) }
      def include?(other)
        return false unless @file == other.file
        return false if @start_line > other.start_line
        return false if @start_line == other.start_line && @start_column > other.start_column
        return false if @end_line < other.end_line
        return false if @end_line == other.end_line && @end_column < other.end_column

        true
      end

      sig { override.params(other: BasicObject).returns(T.nilable(Integer)) }
      def <=>(other)
        return unless Location === other

        to_s <=> other.to_s
      end

      sig { returns(String) }
      def to_s
        "#{@file}:#{@start_line}:#{@start_column}-#{@end_line}:#{@end_column}"
      end
    end
  end
end
