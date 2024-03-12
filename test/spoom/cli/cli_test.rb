# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    class CliTest < TestWithProject
      def setup
        @project.bundle_install!
      end

      def test_display_current_version_short_option
        result = @project.spoom("-v")
        assert_equal("Spoom v#{Spoom::VERSION}", result.out.strip)
      end

      def test_display_current_version_long_option
        result = @project.spoom("--version")
        assert_equal("Spoom v#{Spoom::VERSION}", result.out.strip)
      end

      def test_display_help_long_option
        result = @project.spoom("--help")
        assert_equal(<<~OUT, result.out)
          Commands:
            spoom --version       # Show version
            spoom bump            # Bump Sorbet sigils from `false` to `true` when no errors
            spoom coverage        # Collect metrics related to Sorbet coverage
            spoom deadcode        # Analyze code to find deadcode
            spoom help [COMMAND]  # Describe available commands or one specific command
            spoom lsp             # Send LSP requests to Sorbet
            spoom srb             # Sorbet related commands
            spoom tc              # Run Sorbet and parses its output

          Options:
                [--color], [--no-color], [--skip-color]  # Use colors
                                                         # Default: true
            -p, [--path=PATH]                            # Run spoom in a specific path
                                                         # Default: .

        OUT
      end
    end
  end
end
