# typed: strict
# frozen_string_literal: true

require "minitest"

module Spoom
  module BacktraceFilter
    class Minitest < ::Minitest::BacktraceFilter
      extend T::Sig

      SORBET_PATHS = T.let(Gem.loaded_specs["sorbet-runtime"].full_require_paths.freeze, T::Array[String])

      sig { override.params(bt: T.nilable(T::Array[String])).returns(T::Array[String]) }
      def filter(bt)
        super.select do |line|
          SORBET_PATHS.none? { |path| line.include?(path) }
        end
      end
    end
  end
end
