# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class Location
      extend T::Sig

      sig { returns(String) }
      attr_reader :path

      sig { returns(Integer) }
      attr_reader :line_start, :column_start, :line_end, :column_end

      sig do
        params(
          path: String,
          line_start: Integer,
          column_start: Integer,
          line_end: Integer,
          column_end: Integer,
        ).void
      end
      def initialize(path, line_start, column_start, line_end, column_end)
        @path = path
        @line_start = line_start
        @column_start = column_start
        @line_end = line_end
        @column_end = column_end
      end

      sig { returns(String) }
      def to_s
        "#{path}:#{line_start}:#{column_start}-#{line_end}:#{column_end}"
      end
    end
  end
end
