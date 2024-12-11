# typed: strict
# frozen_string_literal: true

module Spoom
  module Tests
    class TestCase
      extend T::Sig

      sig { returns(String) }
      attr_accessor :klass

      sig { returns(String) }
      attr_reader :name

      sig { returns(String) }
      attr_reader :file

      sig { returns(Integer) }
      attr_reader :line

      sig { params(klass: String, name: String, file: String, line: Integer).void }
      def initialize(klass:, name:, file:, line:)
        @klass = klass
        @name = name
        @file = file
        @line = line
      end

      sig { returns(String) }
      def to_s
        "#{klass}##{name} (#{file}:#{line})"
      end

      sig { params(args: T.untyped).returns(String) }
      def to_json(*args)
        T.unsafe({ klass:, name:, file:, line: }).to_json(*args)
      end
    end
  end
end

# belongs to a test file
# has a name
# has associated files/lines (mapping)
