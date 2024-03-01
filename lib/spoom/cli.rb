# typed: true
# frozen_string_literal: true

require "thor"

require_relative "cli/helper"

require_relative "cli/bump"
require_relative "cli/lsp"
require_relative "cli/coverage"
require_relative "cli/run"

module Spoom
  module Cli
    class Main < Thor
      extend T::Sig
      include Helper

      class_option :color, type: :boolean, default: true, desc: "Use colors"
      class_option :path, type: :string, default: ".", aliases: :p, desc: "Run spoom in a specific path"

      map T.unsafe(["--version", "-v"] => :__print_version)

      desc "bump", "Bump Sorbet sigils from `false` to `true` when no errors"
      subcommand "bump", Spoom::Cli::Bump

      desc "coverage", "Collect metrics related to Sorbet coverage"
      subcommand "coverage", Spoom::Cli::Coverage

      desc "lsp", "Send LSP requests to Sorbet"
      subcommand "lsp", Spoom::Cli::LSP

      desc "tc", "Run Sorbet and parses its output"
      subcommand "tc", Spoom::Cli::Run

      desc "--version", "Show version"
      def __print_version
        puts "Spoom v#{Spoom::VERSION}"
      end

      # Utils

      class << self
        def exit_on_failure?
          true
        end
      end
    end
  end
end
