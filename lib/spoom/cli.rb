# typed: true
# frozen_string_literal: true

require "thor"

require_relative 'cli/helper'

require_relative "cli/bump"
require_relative "cli/config"
require_relative "cli/lsp"
require_relative "cli/coverage"
require_relative "cli/run"

module Spoom
  module Cli
    class Main < Thor
      extend T::Sig
      include Helper

      class_option :color, desc: "Use colors", type: :boolean, default: true
      class_option :path, desc: "Run spoom in a specific path", type: :string, default: ".", aliases: :p
      map T.unsafe(%w[--version -v] => :__print_version)

      desc "bump", "bump Sorbet sigils from `false` to `true` when no errors"
      subcommand "bump", Spoom::Cli::Bump

      desc "config", "manage Sorbet config"
      subcommand "config", Spoom::Cli::Config

      desc "coverage", "collect metrics related to Sorbet coverage"
      subcommand "coverage", Spoom::Cli::Coverage

      desc "lsp", "send LSP requests to Sorbet"
      subcommand "lsp", Spoom::Cli::LSP

      desc "tc", "run Sorbet and parses its output"
      subcommand "tc", Spoom::Cli::Run

      desc "files", "list all the files typechecked by Sorbet"
      def files
        in_sorbet_project!

        path = exec_path
        config = Spoom::Sorbet::Config.parse_file(sorbet_config)
        files = Spoom::Sorbet.srb_files(config, path: path)

        say("Files matching `#{sorbet_config}`:")
        if files.empty?
          say(" NONE")
        else
          tree = FileTree.new(files, strip_prefix: path)
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
