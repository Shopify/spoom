# typed: strict
# frozen_string_literal: true

require "rbi"

require "spoom/source/rewriter"
require "spoom/sorbet/translate/translator"
require "spoom/sorbet/translate/rbs_comments_to_sorbet_sigs"
require "spoom/sorbet/translate/sorbet_assertions_to_rbs_comments"
require "spoom/sorbet/translate/sorbet_sigs_to_rbs_comments"
require "spoom/sorbet/translate/strip_sorbet_sigs"

module Spoom
  module Sorbet
    module Translate
      class Error < Spoom::Error; end

      class << self
        # Deletes all `sig` nodes from the given Ruby code.
        # It doesn't handle type members and class annotations.
        #: (String ruby_contents, file: String) -> String
        def strip_sorbet_sigs(ruby_contents, file:)
          StripSorbetSigs.new(ruby_contents, file: file).rewrite
        end

        # Converts all `sig` nodes to RBS comments in the given Ruby code.
        # It also handles type members and class annotations.
        #: (String ruby_contents, file: String, ?positional_names: bool, ?max_line_length: Integer?) -> String
        def sorbet_sigs_to_rbs_comments(ruby_contents, file:, positional_names: true, max_line_length: nil)
          SorbetSigsToRBSComments.new(ruby_contents, file: file, positional_names: positional_names, max_line_length: max_line_length).rewrite
        end

        # Converts all the RBS comments in the given Ruby code to `sig` nodes.
        # It also handles type members and class annotations.
        #: (String ruby_contents, file: String) -> String
        def rbs_comments_to_sorbet_sigs(ruby_contents, file:)
          RBSCommentsToSorbetSigs.new(ruby_contents, file: file).rewrite
        end

        # Converts all `T.let` and `T.cast` nodes to RBS comments in the given Ruby code.
        # It also handles type members and class annotations.
        #: (String ruby_contents, file: String) -> String
        def sorbet_assertions_to_rbs_comments(ruby_contents, file:)
          SorbetAssertionsToRBSComments.new(ruby_contents, file: file).rewrite
        end
      end
    end
  end
end
