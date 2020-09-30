# typed: true
# frozen_string_literal: true

require "pathname"

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class MetricsTest < Minitest::Test
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
          out, _ = run_cli(PROJECT, "metrics")
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
      end
    end
  end
end
