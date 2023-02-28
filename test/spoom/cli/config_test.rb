# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    class ConfigTest < TestWithProject
      def test_return_error_if_no_sorbet_config
        @project.remove!("sorbet/config")
        result = @project.spoom("config --no-color")
        assert_empty(result.out)
        assert_equal("Error: not in a Sorbet project (`sorbet/config` not found)", result.err&.lines&.first&.chomp)
        refute(result.status)
      end

      def test_display_empty_config
        @project.write_sorbet_config!("")
        result = @project.spoom("config --no-color")
        assert_equal(<<~MSG, result.out)
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
        result = @project.spoom("config --no-color")
        assert_equal(<<~MSG, result.out)
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
        @project.write_sorbet_config!(<<~CFG)
          lib
          --dir=test
          --dir
          tasks
        CFG
        result = @project.spoom("config --no-color")
        assert_equal(<<~MSG, result.out)
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
        @project.write_sorbet_config!(<<~CFG)
          lib/project.rb
          --ignore=lib/main
          --ignore
          test
        CFG
        result = @project.spoom("config --no-color")
        assert_equal(<<~MSG, result.out)
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
        @project.write_sorbet_config!(<<~CFG)
          lib/project.rb
          --ignore=lib/main
          --ignore
          test
          --allowed-extension=.rb
          --allowed-extension=.rbi
          --allowed-extension=.rake
          --allowed-extension=.ru
        CFG
        result = @project.spoom("config --no-color")
        assert_equal(<<~MSG, result.out)
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
        project = new_project("test_config_with_path_option")
        result = project.spoom("config -p #{@project.absolute_path} --no-color")
        assert_equal(<<~MSG, @project.censor_project_path(result.out))
          Found Sorbet config at `/sorbet/config`.

          Paths typechecked:
           * .

          Paths ignored:
           * (default: none)

          Allowed extensions:
           * .rb (default)
           * .rbi (default)
        MSG
        project.destroy!
      end
    end
  end
end
