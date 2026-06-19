# typed: strict
# frozen_string_literal: true

require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/base_translator"
require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs/options"

module Spoom
  module Sorbet
    module Translate
      module RBSCommentsToSorbetSigs
        class HumanReadableTranslator < BaseTranslator
          private

          # Deletes the discarded overload from the source codes
          # @override
          #: (Spoom::RBS::Signature) -> void
          def rewrite_discarded_overload(signature)
            from = adjust_to_line_start(signature.location.start_offset)
            to = adjust_to_line_end(signature.location.end_offset)
            @rewriter << Source::Delete.new(from, to)
          end

          # @override
          #: (
          #|   Spoom::RBS::Annotation,
          #|   parent_node: PrismTypes::anyScopeNode,
          #|   insert_pos: Integer,
          #|   sorbet_replacement: String?
          #| ) -> void
          def apply_class_annotation(annotation, parent_node:, insert_pos:, sorbet_replacement:)
            return unless sorbet_replacement # unknown annotation.

            from = adjust_to_line_start(annotation.location.start_offset)
            to = adjust_to_line_end(annotation.location.end_offset)

            @rewriter << Source::Delete.new(from, to)

            indent = " " * (parent_node.location.start_column + 2)
            newline = parent_node.body.nil? ? "" : "\n"
            @rewriter << Source::Insert.new(insert_pos, "\n#{indent}#{sorbet_replacement}#{newline}")
          end

          # @override
          #: (Spoom::RBS::Signature, type_params: Array[::RBS::AST::TypeParam]) -> void
          def rewrite_type_params_signature(signature, type_params:)
            from = adjust_to_line_start(signature.location.start_offset)
            to = adjust_to_line_end(signature.location.end_offset)
            @rewriter << Source::Delete.new(from, to)
          end

          # @override
          #: (String type_member, parent_node: PrismTypes::anyScopeNode, insert_pos: Integer) -> void
          def insert_type_member(type_member, parent_node:, insert_pos:)
            indent = " " * (parent_node.location.start_column + 2)
            newline = parent_node.body.nil? ? "" : "\n"
            @rewriter << Source::Insert.new(insert_pos, "\n#{indent}#{type_member}#{newline}")
          end

          # @override
          #: (String mixin_name, into: Prism::Node, at: Integer) -> void
          def extend_with(mixin_name, into:, at:)
            indent = " " * (into.location.start_column + 2)
            # `extend` is always followed by an annotation or `type_member`, so it always needs a
            # trailing newline to separate them. Since it's never the last inserted line, that
            # trailing newline can't leave a blank line before `end` (unlike the lines that follow).
            @rewriter << Source::Insert.new(at, "\n#{indent}extend #{mixin_name}\n")
          end
        end
      end
    end
  end
end
