# typed: true
# frozen_string_literal: true

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class CliTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        PROJECT = "project"

        def test_display_current_version_short_option
          out, _ = run_cli("", "-v")
          assert_equal("Spoom v#{Spoom::VERSION}", out&.strip)
        end

        def test_display_current_version_long_option
          out, _ = run_cli("", "--version")
          assert_equal("Spoom v#{Spoom::VERSION}", out&.strip)
        end

        def test_display_help_long_option
          out, _ = run_cli("", "--help")
          assert_equal(<<~OUT, out)
            Commands:
              spoom --version       # show version
              spoom bump            # bump Sorbet sigils from `false` to `true` when no e...
              spoom config          # manage Sorbet config
              spoom coverage        # collect metrics related to Sorbet coverage
              spoom files           # list all the files typechecked by Sorbet
              spoom help [COMMAND]  # Describe available commands or one specific command
              spoom lsp             # send LSP requests to Sorbet
              spoom tc              # run Sorbet and parses its output

            Options:
              [--color], [--no-color]  # Use colors
                                       # Default: true

          OUT
        end

        def test_display_files_from_config
          use_sorbet_config(PROJECT, ".")
          out, _ = run_cli(PROJECT, "files --no-color")
          assert_equal(<<~MSG, out)
            Files matching `sorbet/config`:
              errors/
                errors.rb (true)
              lib/
                defs.rb (true)
                hover.rb (true)
                refs.rb (true)
                sigs.rb (true)
                symbols.rb (true)
                types.rb (true)
          MSG
        end

        def test_display_files_from_config_with_ignored_files
          use_sorbet_config(PROJECT, <<~CFG)
            .
            --ignore=efs
            --ignore=errors
          CFG
          out, _ = run_cli(PROJECT, "files --no-color")
          assert_equal(<<~MSG, out)
            Files matching `sorbet/config`:
              lib/
                hover.rb (true)
                sigs.rb (true)
                symbols.rb (true)
                types.rb (true)
          MSG
        end

        def test_display_files_from_config_with_allowed_exts
          use_sorbet_config(PROJECT, <<~CFG)
            .
            --allowed-extension=.rake
          CFG
          out, _ = run_cli(PROJECT, "files --no-color")
          assert_equal(<<~MSG, out)
            Files matching `sorbet/config`:
              task1.rake (false)
              task2.rake (strong)
          MSG
        end
      end
    end
  end
end
