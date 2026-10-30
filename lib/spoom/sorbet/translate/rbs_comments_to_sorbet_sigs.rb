# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      module RBSCommentsToSorbetSigs
        class << self
          RBS_REWRITE_PATTERN = Regexp.union([
            "#:",
            "#|",
            "# @abstract",
            "# @interface",
            "# @sealed",
            "# @final",
            "# @requires_ancestor:",
            "# @override",
            "# @overridable",
            "# @without_runtime",
          ]).freeze #: Regexp
          private_constant :RBS_REWRITE_PATTERN

          # Detects RBS comment markers (`#:`, `#|`, and supported `# @...` annotations).
          # Use this check to skip parsing files without those markers.
          # It does not validate RBS syntax or check the `typed:` sigil.
          #: (String ruby_contents) -> bool
          def contains_rbs_syntax?(ruby_contents)
            ruby_contents.match?(RBS_REWRITE_PATTERN)
          end

          #: (
          #|   String ruby_contents,
          #|   file: String,
          #|   ?max_line_length: Integer?,
          #|   ?overloads_strategy: Symbol,
          #|   ?erase_generic_types: bool,
          #|   ?preserve_class_type_parameters: bool,
          #|   ?force: bool) -> String
          def rewrite_if_needed(
            ruby_contents,
            file:,
            max_line_length: nil,
            overloads_strategy: :translate_all,
            erase_generic_types: false,
            preserve_class_type_parameters: false,
            force: false
          )
            return ruby_contents unless contains_rbs_syntax?(ruby_contents) &&
              (force || Sigils.contains_valid_sigil?(ruby_contents))

            options = Options.new(
              overloads_strategy:,
              erase_generic_types:,
              preserve_class_type_parameters:,
              output_format: HumanReadableRBIFormat.new(
                max_line_length:,
              ),
            )

            HumanReadableTranslator.new(ruby_contents, file:, options:).rewrite
          end
        end
      end
    end
  end
end

require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/options"
require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/human_readable_translator"
require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/line_matching_translator"
