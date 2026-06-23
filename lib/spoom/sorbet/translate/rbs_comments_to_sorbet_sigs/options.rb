# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      module RBSCommentsToSorbetSigs
        # @abstract
        class BaseRBIFormat
        end

        class HumanReadableRBIFormat < BaseRBIFormat
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

          @default = new #: HumanReadableRBIFormat
          class << self
            #: HumanReadableRBIFormat
            attr_reader :default
          end
        end

        class LineMatchedRBIFormat < BaseRBIFormat
          @default = new #: LineMatchedRBIFormat
          class << self
            #: LineMatchedRBIFormat
            attr_reader :default
          end
        end

        class Options
          #: Symbol
          attr_reader :overloads_strategy

          ALLOWED_OVERLOAD_STRATEGIES = [:translate_all, :translate_last, :raise].freeze

          #: BaseRBIFormat
          attr_reader :output_format

          #: bool
          attr_reader :translate_abstract_methods

          #: (
          #|   ?overloads_strategy: Symbol,
          #|   ?output_format: BaseRBIFormat,
          #|   ?translate_abstract_methods: bool,
          #| ) -> void
          def initialize(
            overloads_strategy: :translate_all,
            output_format: HumanReadableRBIFormat.default,
            translate_abstract_methods: true
          )
            unless ALLOWED_OVERLOAD_STRATEGIES.include?(overloads_strategy)
              raise ArgumentError, "Unknown overloads_strategy: #{overloads_strategy.inspect}. " \
                "Must be one of: #{ALLOWED_OVERLOAD_STRATEGIES.map(&:inspect).join(", ")}"
            end

            @overloads_strategy = overloads_strategy
            @output_format = output_format
            @translate_abstract_methods = translate_abstract_methods

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
