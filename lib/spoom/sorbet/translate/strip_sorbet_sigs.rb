# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      # Deletes all `sig` nodes from the given Ruby code.
      # It doesn't handle type members and class annotations.
      class StripSorbetSigs < Translator
        # @override
        #: (Prism::CallNode node) -> void
        def visit_call_node(node)
          return unless sorbet_sig?(node)

          @rewriter << Source::Delete.new(
            adjust_to_line_start(node.location.start_offset),
            adjust_to_line_end(node.location.end_offset),
          )
        end
      end
    end
  end
end
