# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      module RBSCommentsToSorbetSigs
        class << self
          RBS_ANNOTATION_MARKERS = [
            "# @abstract",
            "# @interface",
            "# @sealed",
            "# @final",
            "# @requires_ancestor:",
            "# @override",
            "# @overridable",
            "# @without_runtime",
          ].freeze #: Array[String]
          RBS_REWRITE_PATTERN = Regexp.union(["#:", "#|", *RBS_ANNOTATION_MARKERS]).freeze #: Regexp
          private_constant :RBS_ANNOTATION_MARKERS, :RBS_REWRITE_PATTERN

          #: (String source) -> bool
          def contains_rbs_syntax?(source)
            Sigils.contains_valid_sigil?(source) && source.match?(RBS_REWRITE_PATTERN)
          end

          #: (String ruby_contents, file: String, ?max_line_length: Integer?, ?overloads_strategy: Symbol) -> String
          def rewrite_if_needed(ruby_contents, file:, max_line_length: nil, overloads_strategy: :translate_all)
            return ruby_contents unless contains_rbs_syntax?(ruby_contents)

            HumanReadableTranslator.new(ruby_contents, file:, max_line_length:, overloads_strategy:).rewrite
          end
        end
      end
    end
  end
end

require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/human_readable_translator"
