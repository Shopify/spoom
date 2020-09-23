# typed: true
# frozen_string_literal: true

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class CliTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        def test_display_current_version_short_option
          out, _ = run_cli("", "-v")
          assert_equal("Spoom v#{Spoom::VERSION}", out&.strip)
        end

        def test_display_current_version_long_option
          out, _ = run_cli("", "--version")
          assert_equal("Spoom v#{Spoom::VERSION}", out&.strip)
        end
      end
    end
  end
end
