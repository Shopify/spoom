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

      sig { override.params(other: BasicObject).returns(T.nilable(Integer)) }
      def <=>(other)
        return nil unless Location === other

        to_s <=> other.to_s
      end

      sig { returns(String) }
      def to_s
        "#{@file}:#{@start_line}:#{@start_column}-#{@end_line}:#{@end_column}"
      end
    end
  end
end
