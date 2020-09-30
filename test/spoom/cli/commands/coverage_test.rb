# typed: true
# frozen_string_literal: true

require "pathname"

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class CoverageTest < Minitest::Test
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

        def test_display_metrics
          out, _ = run_cli(PROJECT, "coverage snapshot")
          assert_equal(<<~MSG, out)
            Content:
              files: 6
              modules: 2
              classes: 16 (including singleton classes)
              methods: 22

            Sigils:
              true: 6 (100%)

            Methods:
              with signature: 2 (9%)
              without signature: 20 (91%)

            Calls:
              typed: 47 (92%)
              untyped: 4 (8%)
          MSG
        end

        def test_display_metrics_do_not_show_errors
          use_sorbet_config(PROJECT, ".")
          out, _ = run_cli(PROJECT, "coverage")
          assert_equal(<<~MSG, out)
            Content:
              files: 7
              modules: 2
              classes: 18 (including singleton classes)
              methods: 25

            Sigils:
              true: 7 (100%)

            Methods:
              with signature: 3 (12%)
              without signature: 22 (88%)

            Calls:
              typed: 53 (87%)
              untyped: 8 (13%)
          MSG
        end
      end
    end
  end
end
