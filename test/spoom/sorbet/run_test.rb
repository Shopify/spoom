# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class RunTest < Minitest::Test
      include Spoom::TestHelper

      def setup
        @project = spoom_project("test_run")
        @project.sorbet_config(".")
        @project.write("test.rb")
      end

      def teardown
        @project.destroy
      end

      def test_run_srb_from_bundler
        @project.gemfile("gem 'sorbet'")
        Bundler.with_clean_env do
          out, status = Spoom::Sorbet.srb(path: @project.path, capture_err: true)
          assert_equal(<<~OUT, out)
            No errors! Great job.
          OUT
          assert(status)
        end
      end

      def test_run_srb_from_bundler_not_found
        @project.gemfile("")
        Bundler.with_clean_env do
          out, status = Spoom::Sorbet.srb(path: @project.path, capture_err: true)
          assert_match(/Gem::Exception: can't find executable srb for gem sorbet./, out)
          refute(status)
        end
      end

      def test_run_sorbet_from_path
        Bundler.with_clean_env do
          out, status = Spoom::Sorbet.srb(
            "-h",
            path: @project.path,
            capture_err: true,
            sorbet_bin: Spoom::Sorbet::BIN_PATH
          )
          assert_equal(<<~OUT, out)
            Typechecker for Ruby
            Usage:
              sorbet [OPTION...] <path 1> <path 2> ...

              -e, string     Parse an inline ruby string (default: "")
              -q, --quiet    Silence all non-critical errors
              -v, --verbose  Verbosity level [0-3]
              -h,            Show short help
                  --help     Show long help
                  --version  Show version

          OUT
          assert(status)
        end
      end

      def test_run_sorbet_tc_from_path
        Bundler.with_clean_env do
          out, status = Spoom::Sorbet.srb_tc(
            path: @project.path,
            capture_err: true,
            sorbet_bin: Spoom::Sorbet::BIN_PATH
          )
          assert_equal(<<~OUT, out)
            No errors! Great job.
          OUT
          assert(status)
        end
      end
    end
  end
end
