# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Cli
    class ConfigTest < Minitest::Test
      include Spoom::TestHelper

      def setup
        @project = spoom_project
      end

      def teardown
        @project.destroy
      end

      def test_return_error_if_no_sorbet_config
        @project.remove("sorbet/config")
        out, err, status = @project.bundle_exec("spoom config --no-color")
        assert_empty(out)
        assert_equal("Error: not in a Sorbet project (`sorbet/config` not found)", err.lines.first.chomp)
        refute(status)
      end

      def test_display_empty_config
        @project.sorbet_config("")
        out, _ = @project.bundle_exec("spoom config --no-color")
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
        out, _ = @project.bundle_exec("spoom config --no-color")
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
        @project.sorbet_config(<<~CFG)
          lib
          --dir=test
          --dir
          tasks
        CFG
        out, _ = @project.bundle_exec("spoom config --no-color")
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
        @project.sorbet_config(<<~CFG)
          lib/project.rb
          --ignore=lib/main
          --ignore
          test
        CFG
        out, _ = @project.bundle_exec("spoom config --no-color")
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
        @project.sorbet_config(<<~CFG)
          lib/project.rb
          --ignore=lib/main
          --ignore
          test
          --allowed-extension=.rb
          --allowed-extension=.rbi
          --allowed-extension=.rake
          --allowed-extension=.ru
        CFG
        out, _ = @project.bundle_exec("spoom config --no-color")
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

      def test_config_with_path_option
        project = spoom_project("test_config_with_path_option")
        out, _ = project.bundle_exec("spoom config -p #{@project.path} --no-color")
        assert_equal(<<~MSG, out)
          Found Sorbet config at `/tmp/spoom/tests/test_config_with_path_option/sorbet/config`.

          Paths typechecked:
           * .

          Paths ignored:
           * (default: none)

          Allowed extensions:
           * .rb (default)
           * .rbi (default)
        MSG
        project.destroy
      end
    end
  end
end
