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
      end
    end
  end
end
