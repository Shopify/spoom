# typed: strict
# frozen_string_literal: true

module Spoom
  module Tests
    class Coverage
      extend T::Sig

      attr_accessor :results

      def initialize
        @results = T.let([], T::Array[[TestCase, T::Hash[String, T::Array[T.nilable(Integer)]]]])
      end

      def <<((test_case, coverage))
        @results << [test_case, coverage]
      end

      def to_json
        results = []
        @results.each do |test_case, coverage|
          results << { test_case: test_case, coverage: coverage }
        end
        results.to_json
      end
    end
  end
end
