# typed: strict
# frozen_string_literal: true

require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/base_translator"
require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/options"

module Spoom
  module Sorbet
    module Translate
      module RBSCommentsToSorbetSigs
        class LineMatchingTranslator < BaseTranslator
          private

          # Comments out the discarded overload
          # @override
          #: (Spoom::RBS::Signature) -> void
          def rewrite_discarded_overload(signature)
            @rewriter << Source::Insert.new(signature.location.start_offset + 1, " RBS_DISCARDED_OVERLOAD")

            signature.continuation_locations.each do |location|
              @rewriter << Source::Insert.new(location.start_offset + 1, " RBS_DISCARDED_OVERLOAD:")
            end
          end

          # @override
          #: (
          #|   Spoom::RBS::Annotation,
          #|   parent_node: PrismTypes::anyScopeNode,
          #|   insert_pos: Integer,
          #|   sorbet_replacement: String?
          #| ) -> void
          def apply_class_annotation(annotation, parent_node:, insert_pos:, sorbet_replacement:)
            case annotation.string
            when /^@requires_ancestor: /
              @rewriter << Source::Replace.new(
                annotation.location.start_offset,
                annotation.location.end_offset,
                "# RBS_REWRITTEN_ANNOTATION: #{annotation.string}\n",
              )
            else
              rewrite_annotation(annotation, is_known: !!sorbet_replacement)
            end

            if sorbet_replacement
              @rewriter << Source::Insert.new(insert_pos, "; #{sorbet_replacement}")
            end
          end

          # @override
          #: (Spoom::RBS::Signature, type_params: Array[::RBS::AST::TypeParam]) -> void
          def rewrite_type_params_signature(signature, type_params:)
            # Rewrite `#: [A, B]` into `# RBS_WRITTEN_ANNOTATION: [A, B]`
            @rewriter << Source::Replace.new(
              signature.location.start_offset,
              signature.location.start_offset + 1, # the `#:` prefix
              "# RBS_WRITTEN_ANNOTATION:",
            )

            # Rewrite each continuation line `#| B]` into `# RBS_WRITTEN_ANNOTATION: B]`
            signature.continuation_locations.each do |location|
              @rewriter << Source::Replace.new(
                location.start_offset,
                location.start_offset + 1, # the `#|` continuation prefix
                "# RBS_WRITTEN_ANNOTATION:",
              )
            end
          end

          # @override
          #: (String type_member, parent_node: PrismTypes::anyScopeNode, insert_pos: Integer) -> void
          def insert_type_member(type_member, parent_node:, insert_pos:)
            @rewriter << Source::Insert.new(insert_pos, "; #{type_member}")
          end

          # @override
          #: (Spoom::RBS::Annotation, is_known: bool) -> void
          def rewrite_annotation(annotation, is_known:)
            annotation_start = annotation.location.start_offset + 1 # skip past the `#`
            text = is_known ? " RBS_REWRITTEN_ANNOTATION:" : " RBS_IGNORED_UNKNOWN_ANNOTATION:"
            @rewriter << Source::Insert.new(annotation_start, text)
          end

          # @override
          #: (String mixin_name, into: Prism::Node, at: Integer) -> void
          def extend_with(mixin_name, into:, at:)
            insert_pos = at

            @rewriter << Source::Insert.new(insert_pos, "; extend #{mixin_name}")
          end

          # @override
          #: (of: String, to_height_of: Spoom::RBS::Comment) -> String
          def pad_out_line_count(of:, to_height_of:)
            original_line_count = to_height_of.location.end_line - to_height_of.location.start_line + 1
            replacement_line_count = of.count("\n")
            needed_padding_lines = original_line_count - replacement_line_count
            return of if needed_padding_lines == 0

            if needed_padding_lines < 0
              raise <<~MSG
                Replacement content has more lines than the original content.
                Original:
                  #{to_height_of.string}
                Replacement content:
                  #{of}
              MSG
            end

            of + "\n" * needed_padding_lines
          end
        end
      end
    end
  end
end
