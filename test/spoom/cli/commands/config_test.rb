# typed: true
# frozen_string_literal: true

require "pathname"

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class ConfigTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        def test_project
          "project"
        end

        before_all do
          install_sorbet("project")
        end

        def teardown
          use_sorbet_config(test_project, nil)
        end

        def test_return_error_if_no_sorbet_config
          use_sorbet_config(test_project, nil)
          _, err = run_cli(test_project, "config")
          assert_equal(<<~MSG, err)
            Error: not in a Sorbet project (no sorbet/config)
          MSG
        end

        def test_display_empty_config
          use_sorbet_config(test_project, "")
          out, _ = run_cli(test_project, "config")
          assert_equal(<<~MSG, out)
            Found Sorbet config at `sorbet/config`.

            Paths typechecked:
             * (default: .)

            Paths ignored:
             * (default: none)

            Allowed extensions:
             * .rb (default)
             * .rbi (default)
          MSG
        end

        def test_display_simple_config
          use_sorbet_config(test_project, ".")
          out, _ = run_cli(test_project, "config")
          assert_equal(<<~MSG, out)
            Found Sorbet config at `sorbet/config`.

            Paths typechecked:
             * .

            Paths ignored:
             * (default: none)

            Allowed extensions:
             * .rb (default)
             * .rbi (default)
          MSG
        end

        def test_display_multi_config
          use_sorbet_config(test_project, <<~CFG)
            lib
            --dir=test
            --dir
            tasks
          CFG
          out, _ = run_cli(test_project, "config")
          assert_equal(<<~MSG, out)
            Found Sorbet config at `sorbet/config`.

            Paths typechecked:
             * lib
             * test
             * tasks

            Paths ignored:
             * (default: none)

            Allowed extensions:
             * .rb (default)
             * .rbi (default)
          MSG
        end

        def test_display_config_with_ignored_files
          use_sorbet_config(test_project, <<~CFG)
            lib/project.rb
            --ignore=lib/main
            --ignore
            test
          CFG
          out, _ = run_cli(test_project, "config")
          assert_equal(<<~MSG, out)
            Found Sorbet config at `sorbet/config`.

            Paths typechecked:
             * lib/project.rb

            Paths ignored:
             * lib/main
             * test

            Allowed extensions:
             * .rb (default)
             * .rbi (default)
          MSG
        end

        def test_display_config_with_allowed_extensions
          use_sorbet_config(test_project, <<~CFG)
            lib/project.rb
            --ignore=lib/main
            --ignore
            test
            --allowed-extension=.rb
            --allowed-extension=.rbi
            --allowed-extension=.rake
            --allowed-extension=.ru
          CFG
          out, _ = run_cli(test_project, "config")
          assert_equal(<<~MSG, out)
            Found Sorbet config at `sorbet/config`.

            Paths typechecked:
             * lib/project.rb

            Paths ignored:
             * lib/main
             * test

            Allowed extensions:
             * .rb
             * .rbi
             * .rake
             * .ru
          MSG
        end

        def test_display_files_from_config
          use_sorbet_config(test_project, ".")
          out, _ = run_cli(test_project, "config files")
          assert_equal(<<~MSG, out)
            Files matching `sorbet/config`:
             * errors/errors.rb
             * lib/defs.rb
             * lib/hover.rb
             * lib/refs.rb
             * lib/sigs.rb
             * lib/symbols.rb
             * lib/types.rb
          MSG
        end

        def test_display_files_from_config_with_ignored_files
          use_sorbet_config(test_project, <<~CFG)
            .
            --ignore=efs
            --ignore=errors
          CFG
          out, _ = run_cli(test_project, "config files")
          assert_equal(<<~MSG, out)
            Files matching `sorbet/config`:
             * lib/hover.rb
             * lib/sigs.rb
             * lib/symbols.rb
             * lib/types.rb
          MSG
        end

        def test_display_files_from_config_with_allowed_exts
          use_sorbet_config(test_project, <<~CFG)
            .
            --allowed-extension=.rake
          CFG
          out, _ = run_cli(test_project, "config files")
          assert_equal(<<~MSG, out)
            Files matching `sorbet/config`:
             * task1.rake
             * task2.rake
          MSG
        end
      end
    end
  end
end
