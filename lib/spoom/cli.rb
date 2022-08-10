# typed: true
# frozen_string_literal: true

require "thor"

require_relative "cli/helper"

require_relative "cli/bump"
require_relative "cli/config"
require_relative "cli/docs"
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

      desc "config", "Manage Sorbet config"
      subcommand "config", Spoom::Cli::Config

      desc "coverage", "Collect metrics related to Sorbet coverage"
      subcommand "coverage", Spoom::Cli::Coverage

      desc "docs", "TODO"
      subcommand "docs", Spoom::Cli::Docs

      desc "lsp", "Send LSP requests to Sorbet"
      subcommand "lsp", Spoom::Cli::LSP

      desc "tc", "Run Sorbet and parses its output"
      subcommand "tc", Spoom::Cli::Run

      desc "files", "List all the files typechecked by Sorbet"
      option :tree, type: :boolean, default: true, desc: "Display list as an indented tree"
      option :rbi, type: :boolean, default: true, desc: "Show RBI files"
      def files
        in_sorbet_project!

        path = exec_path
        config = sorbet_config
        files = Spoom::Sorbet.srb_files(config, path: path)

        unless options[:rbi]
          files = files.reject { |file| file.end_with?(".rbi") }
        end

        if files.empty?
          say_error("No file matching `#{sorbet_config_file}`")
          exit(1)
        end

        if options[:tree]
          tree = FileTree.new(files, strip_prefix: path)
          tree.print(colors: options[:color], indent_level: 0)
        else
          puts files
        end
      end

      desc "--version", "Show version"
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
