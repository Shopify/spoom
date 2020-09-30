# typed: true
# frozen_string_literal: true

require "thor"

require_relative "cli/commands/bump"
require_relative "cli/commands/config"
require_relative "cli/commands/lsp"
require_relative "cli/commands/coverage"
require_relative "cli/commands/run"

module Spoom
  module Cli
    class Main < Thor
      extend T::Sig
      include Spoom::Cli::CommandHelper

      class_option :color, desc: "Use colors", type: :boolean, default: true
      map T.unsafe(%w[--version -v] => :__print_version)

      desc "bump", "bump Sorbet sigils from `false` to `true` when no errors"
      subcommand "bump", Spoom::Cli::Commands::Bump

      desc "config", "manage Sorbet config"
      subcommand "config", Spoom::Cli::Commands::Config

      desc "coverage", "collect metrics related to Sorbet coverage"
      subcommand "coverage", Spoom::Cli::Commands::Coverage

      desc "lsp", "send LSP requests to Sorbet"
      subcommand "lsp", Spoom::Cli::Commands::LSP

      desc "tc", "run Sorbet and parses its output"
      subcommand "tc", Spoom::Cli::Commands::Run

      desc "files", "list all the files typechecked by Sorbet"
      def files
        in_sorbet_project!
        config = Spoom::Sorbet::Config.parse_file(Spoom::Config::SORBET_CONFIG)
        files = Spoom::Sorbet.srb_files(config)

        say("Files matching `#{Spoom::Config::SORBET_CONFIG}`:")
        if files.empty?
          say(" NONE")
        else
          tree = FileTree.new(files)
          tree.print(colors: options[:color], indent_level: 2)
        end
      end

      desc "--version", "show version"
      def __print_version
        puts "Spoom v#{Spoom::VERSION}"
      end

      # Utils

      def self.exit_on_failure?
        true
      end
    end
  end
end
