# typed: true
# frozen_string_literal: true

require "pathname"

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class RunTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        PROJECT = "project"

        before_all do
          install_sorbet(PROJECT)
        end

        def setup
          use_sorbet_config(PROJECT, <<~CFG)
            .
            --ignore=errors
          CFG
        end

        def teardown
          use_sorbet_config(PROJECT, nil)
        end

        def test_return_error_if_no_sorbet_config
          use_sorbet_config(PROJECT, nil)
          _, err = run_cli(PROJECT, "tc")
          assert_equal(<<~MSG, err)
            Error: not in a Sorbet project (no sorbet/config)
          MSG
        end

        def test_display_no_errors_without_filter
          _, err = run_cli(PROJECT, "tc")
          assert_equal(<<~MSG, err)
            No errors! Great job.
          MSG
        end

        def test_display_no_errors_with_sort
          _, err = run_cli(PROJECT, "tc --no-color -s")
          assert_equal(<<~MSG, err)
            No errors! Great job.
          MSG
        end

        def test_display_errors_with_sort_default
          use_sorbet_config(PROJECT, ".")
          _, err = run_cli(PROJECT, "tc --no-color -s")
          assert_equal(<<~MSG, err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            5002 - errors/errors.rb:5: Unable to resolve constant `C`
            7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
            Errors: 7
          MSG
        end

        def test_display_errors_with_sort_code
          use_sorbet_config(PROJECT, ".")
          _, err = run_cli(PROJECT, "tc --no-color -s code")
          assert_equal(<<~MSG, err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            5002 - errors/errors.rb:5: Unable to resolve constant `C`
            7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
            Errors: 7
          MSG
        end

        def test_display_errors_with_limit
          use_sorbet_config(PROJECT, ".")
          _, err = run_cli(PROJECT, "tc --no-color -l 1")
          assert_equal(<<~MSG, err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            Errors: 1 shown, 7 total
          MSG
        end

        def test_display_errors_with_code
          use_sorbet_config(PROJECT, ".")
          _, err = run_cli(PROJECT, "tc --no-color -c 7004")
          assert_equal(<<~MSG, err)
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
            Errors: 2 shown, 7 total
          MSG
        end

        def test_display_errors_with_limit_and_code
          use_sorbet_config(PROJECT, ".")
          _, err = run_cli(PROJECT, "tc --no-color -c 7004 -l 1")
          assert_equal(<<~MSG, err)
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            Errors: 1 shown, 7 total
          MSG
        end

        def test_display_errors_with_sort_and_limit
          use_sorbet_config(PROJECT, ".")
          _, err = run_cli(PROJECT, "tc --no-color -s code -l 1")
          assert_equal(<<~MSG, err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            Errors: 1 shown, 7 total
          MSG
        end

        # Metrics

        def test_display_metrics
          out, _ = run_cli(PROJECT, "tc metrics")
          assert_equal(<<~MSG, out)
            Sigils:
              files: 6
              true: 6 (100%)

            Classes & Modules:
              classes: 16
              modules: 2

            Methods:
              methods: 22
              signatures: 2 (9%)

            Sends:
              sends: 51
              typed: 47 (92%)
          MSG
        end
      end
    end
  end
end
