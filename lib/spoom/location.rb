# typed: strict
# frozen_string_literal: true

module Spoom
  class Location
    extend T::Sig

    include Comparable

    class LocationError < Spoom::Error; end

    class << self
      extend T::Sig

      sig { params(location_string: String).returns(Location) }
      def from_string(location_string)
        file, rest = location_string.split(":", 2)
        raise LocationError, "Invalid location string `#{location_string}`: missing file name" unless file

        return new(file) if rest.nil?

        start_line, rest = rest.split(":", 2)
        if rest.nil?
          start_line, end_line = T.must(start_line).split("-", 2)
          raise LocationError, "Invalid location string `#{location_string}`: missing end line" unless end_line

          return new(file, start_line: start_line.to_i, end_line: end_line.to_i) if end_line
        end

        start_column, rest = rest.split("-", 2)
        raise LocationError, "Invalid location string `#{location_string}`: missing end line and column" if rest.nil?

        end_line, end_column = rest.split(":", 2)
        raise LocationError,
          "Invalid location string `#{location_string}`: missing end column" unless end_line && end_column

        new(
          file,
          start_line: start_line.to_i,
          start_column: start_column.to_i,
          end_line: end_line.to_i,
          end_column: end_column.to_i,
        )
      end

      sig { params(file: String, location: Prism::Location).returns(Location) }
      def from_prism(file, location)
        new(
          file,
          start_line: location.start_line,
          start_column: location.start_column,
          end_line: location.end_line,
          end_column: location.end_column,
        )
      end
    end

    sig { returns(String) }
    attr_reader :file

    sig { returns(T.nilable(Integer)) }
    attr_reader :start_line, :start_column, :end_line, :end_column

    sig do
      params(
        file: String,
        start_line: T.nilable(Integer),
        start_column: T.nilable(Integer),
        end_line: T.nilable(Integer),
        end_column: T.nilable(Integer),
      ).void
    end
    def initialize(file, start_line: nil, start_column: nil, end_line: nil, end_column: nil)
      raise LocationError,
        "Invalid location: end line is required if start line is provided" if start_line && !end_line
      raise LocationError,
        "Invalid location: start line is required if end line is provided" if !start_line && end_line
      raise LocationError,
        "Invalid location: end column is required if start column is provided" if start_column && !end_column
      raise LocationError,
        "Invalid location: start column is required if end column is provided" if !start_column && end_column
      raise LocationError,
        "Invalid location: lines are required if columns are provided" if start_column && !start_line

      @file = file
      @start_line = start_line
      @start_column = start_column
      @end_line = end_line
      @end_column = end_column
    end

    sig { params(other: Location).returns(T::Boolean) }
    def include?(other)
      return false unless @file == other.file
      return false if (@start_line || -Float::INFINITY) > (other.start_line || -Float::INFINITY)
      return false if @start_line == other.start_line &&
        (@start_column || -Float::INFINITY) > (other.start_column || -Float::INFINITY)
      return false if (@end_line || Float::INFINITY) < (other.end_line || Float::INFINITY)
      return false if @end_line == other.end_line &&
        (@end_column || Float::INFINITY) < (other.end_column || Float::INFINITY)

      true
    end

    sig { override.params(other: BasicObject).returns(T.nilable(Integer)) }
    def <=>(other)
      return unless Location === other

      comparison_array_self = [
        @file,
        @start_line || -Float::INFINITY,
        @start_column || -Float::INFINITY,
        @end_line || Float::INFINITY,
        @end_column || Float::INFINITY,
      ]

      comparison_array_other = [
        other.file,
        other.start_line || -Float::INFINITY,
        other.start_column || -Float::INFINITY,
        other.end_line || Float::INFINITY,
        other.end_column || Float::INFINITY,
      ]

      comparison_array_self <=> comparison_array_other
    end

    sig { returns(String) }
    def to_s
      if @start_line && @start_column
        "#{@file}:#{@start_line}:#{@start_column}-#{@end_line}:#{@end_column}"
      elsif @start_line
        "#{@file}:#{@start_line}-#{@end_line}"
      else
        @file
      end
    end
  end
end
