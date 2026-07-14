# typed: strict
# frozen_string_literal: true

require "minitest"

module Spoom
  module BacktraceFilter
    class Minitest < ::Minitest::BacktraceFilter
      SORBET_PATHS = Gem.loaded_specs["sorbet-runtime"].full_require_paths.freeze #: Array[String]

      # @override
      #: (Array[String]? bt) -> Array[String]
      def filter(bt)
        super.select do |line|
          !SORBET_PATHS.intersect?(line)
        end
      end
    end
  end
end
