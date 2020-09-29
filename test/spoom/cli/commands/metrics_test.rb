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
            Sigils:
              files: 6
              true: 6 (100%)

            Classes & Modules:
              classes: 16 (including singleton classes)
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
