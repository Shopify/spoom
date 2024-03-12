# typed: strict
# frozen_string_literal: true

require_relative "srb/bump"
require_relative "srb/coverage"
require_relative "srb/lsp"
require_relative "srb/tc"

module Spoom
  module Cli
    module Srb
      class Main < Thor
        desc "lsp", "Send LSP requests to Sorbet"
        subcommand "lsp", Spoom::Cli::Srb::LSP

        desc "coverage", "Collect metrics related to Sorbet coverage"
        subcommand "coverage", Spoom::Cli::Srb::Coverage

        desc "bump", "Change Sorbet sigils from one strictness to another when no errors"
        subcommand "bump", Spoom::Cli::Srb::Bump

        desc "tc", "Run typechecking with advanced options"
        subcommand "tc", Spoom::Cli::Srb::Tc
      end
    end
  end
end
