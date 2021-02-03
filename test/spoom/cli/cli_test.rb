# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Cli
    class CliTest < Minitest::Test
      include Spoom::TestHelper

      def setup
        @project = spoom_project("test_cli")
      end

      def teardown
        @project.destroy
      end

      PROJECT = "project"

      def test_display_current_version_short_option
        out, _ = @project.bundle_exec("spoom -v")
        assert_equal("Spoom v#{Spoom::VERSION}", out&.strip)
      end

      def test_display_current_version_long_option
        out, _ = @project.bundle_exec("spoom --version")
        assert_equal("Spoom v#{Spoom::VERSION}", out&.strip)
      end

      def test_display_help_long_option
        out, _ = @project.bundle_exec("spoom --help")
        assert_equal(<<~OUT, out)
          Commands:
            spoom --version       # Show version
            spoom bump            # Bump Sorbet sigils from `false` to `true` when no e...
            spoom config          # Manage Sorbet config
            spoom coverage        # Collect metrics related to Sorbet coverage
            spoom files           # List all the files typechecked by Sorbet
            spoom help [COMMAND]  # Describe available commands or one specific command
            spoom lsp             # Send LSP requests to Sorbet
            spoom tc              # Run Sorbet and parses its output

          Options:
                [--color], [--no-color]  # Use colors
                                         # Default: true
            p, [--path=PATH]             # Run spoom in a specific path
                                         # Default: .

        OUT
      end

      def test_display_files_returns_1_if_no_file
        @project.sorbet_config(".")
        out, err, status = @project.bundle_exec("spoom files --no-color")
        assert_equal(<<~MSG, err)
          Error: No file matching `sorbet/config`
        MSG
        assert_empty(out)
        refute(status)
      end

      def test_display_files_from_config
        @project.write("test/a.rb", "# typed: ignore")
        @project.write("test/b.rb", "# typed: false")
        @project.write("lib/c.rb", "# typed: true")
        @project.write("lib/d.rb", "# typed: strict")
        @project.write("lib/e.rb", "# typed: strong")
        @project.write("lib/f.rb", "# typed: __STDLIB_INTERNAL")
        @project.sorbet_config(".")
        out, _ = @project.bundle_exec("spoom files --no-color")
        assert_equal(<<~MSG, out)
          Files matching `sorbet/config`:
            lib/
              c.rb (true)
              d.rb (strict)
              e.rb (strong)
              f.rb (__STDLIB_INTERNAL)
            test/
              a.rb (ignore)
              b.rb (false)
        MSG
      end

      def test_display_files_from_config_with_ignored_files
        @project.write("test/a.rb", "# typed: ignore")
        @project.write("test/b.rb", "# typed: false")
        @project.write("lib/c.rb", "# typed: true")
        @project.write("lib/d.rb", "# typed: strict")
        @project.write("lib/e.rb", "# typed: strong")
        @project.write("lib/f.rb", "# typed: __STDLIB_INTERNAL")
        @project.sorbet_config(<<~CFG)
          .
          --ignore=test
        CFG
        out, _ = @project.bundle_exec("spoom files --no-color")
        assert_equal(<<~MSG, out)
          Files matching `sorbet/config`:
            lib/
              c.rb (true)
              d.rb (strict)
              e.rb (strong)
              f.rb (__STDLIB_INTERNAL)
        MSG
      end

      def test_display_files_from_config_with_allowed_exts
        @project.write("test/a.rake", "# typed: ignore")
        @project.write("test/b.rbi", "# typed: false")
        @project.write("lib/c.rbi", "# typed: true")
        @project.write("lib/d.ru", "# typed: strict")
        @project.write("lib/e.rb", "# typed: strong")
        @project.write("lib/f.rb", "# typed: __STDLIB_INTERNAL")
        @project.sorbet_config(<<~CFG)
          .
          --allowed-extension=.rake
          --allowed-extension=.ru
          --allowed-extension=.rb
        CFG
        out, _ = @project.bundle_exec("spoom files --no-color")
        assert_equal(<<~MSG, out)
          Files matching `sorbet/config`:
            lib/
              d.ru (strict)
              e.rb (strong)
              f.rb (__STDLIB_INTERNAL)
            test/
              a.rake (ignore)
        MSG
      end

      def test_display_files_with_path_option
        project = spoom_project("test_files")
        project.sorbet_config(".")
        project.write("lib/file1.rb", "# typed: true")
        project.write("lib/file2.rb", "# typed: true")

        out, _ = @project.bundle_exec("spoom files --no-color --path #{project.path}")
        assert_equal(<<~MSG, out)
          Files matching `/tmp/spoom/tests/test_files/sorbet/config`:
            lib/
              file1.rb (true)
              file2.rb (true)
        MSG
      end
    end
  end
end
