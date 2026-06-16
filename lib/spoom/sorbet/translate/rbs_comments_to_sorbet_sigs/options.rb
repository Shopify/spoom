# typed: strict
# frozen_string_literal: true

# require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/base_translator"

module Spoom
  module Sorbet
    module Translate
      module RBSCommentsToSorbetSigs
        class BaseRBIFormat # TODO: move to RBI gem
        end

        class DefaultRBIFormat < BaseRBIFormat # TODO: move to RBI gem
          #: Integer?
          attr_reader :max_line_length

          #: (
          #|   ?max_line_length: Integer?,
          #| ) -> void
          def initialize(max_line_length: nil)
            super()
            @max_line_length = max_line_length

            freeze
          end

          @default = new #: DefaultRBIFormat
          class << self
            #: DefaultRBIFormat
            attr_reader :default
          end
        end

        class Options
          #: Symbol
          attr_reader :overloads_strategy

          ALLOWED_OVERLOAD_STRATEGIES = [:translate_all, :translate_last, :raise].freeze #: Array[Symbol]

          #: bool
          attr_reader :erase_generic_types

          #: BaseRBIFormat
          attr_reader :output_format

          #: (
          # :translate_all | :translate_last | :raise
          #|   ?overloads_strategy: Symbol,
          #|   ?erase_generic_types: bool,
          #|   ?output_format: BaseRBIFormat,
          #| ) -> void
          def initialize(
            overloads_strategy: :translate_all,
            erase_generic_types: false,
            output_format: DefaultRBIFormat.default
          )
            unless ALLOWED_OVERLOAD_STRATEGIES.include?(overloads_strategy)
              raise ArgumentError, "Unknown overloads_strategy: #{overloads_strategy.inspect}. " \
                "Must be one of: #{ALLOWED_OVERLOAD_STRATEGIES.map(&:inspect).join(", ")}"
            end

            @overloads_strategy = overloads_strategy
            @erase_generic_types = erase_generic_types
            @output_format = output_format

            freeze
          end

          @default = new #: Options
          class << self
            #: Options
            attr_reader :default
          end
        end
      end
    end
  end
end
