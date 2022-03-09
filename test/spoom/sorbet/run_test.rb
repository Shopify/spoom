# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class RunTest < Minitest::Test
      include Spoom::TestHelper

      def setup
        @project = spoom_project
        @project.write("test.rb")
      end

      def teardown
        @project.destroy
      end

      def test_run_srb_from_bundler
        @project.gemfile(<<~GEM)
          source 'https://rubygems.org'
          gem 'sorbet'
        GEM
        Bundler.with_unbundled_env do
          _, _, status = @project.bundle_install
          assert(status)

          out, status, exit_code = Spoom::Sorbet.srb(path: @project.path, capture_err: true)
          assert_equal(<<~OUT, out)
            No errors! Great job.
          OUT
          assert(status)
          assert_equal(0, exit_code)
        end
      end

      def test_run_srb_from_bundler_not_found
        @project.gemfile("source 'https://rubygems.org'")
        Bundler.with_unbundled_env do
          _, _, status = @project.bundle_install
          assert(status)

          _, status, exit_code = Spoom::Sorbet.srb(path: @project.path, capture_err: true)
          refute(status)
          assert_equal(1, exit_code)
        end
      end

      def test_run_sorbet_from_path
        Bundler.with_unbundled_env do
          out, status, exit_code = Spoom::Sorbet.srb(
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
          assert_equal(0, exit_code)
        end
      end

      def test_run_sorbet_tc_from_path
        Bundler.with_unbundled_env do
          out, status, exit_code = Spoom::Sorbet.srb_tc(
            path: @project.path,
            capture_err: true,
            sorbet_bin: Spoom::Sorbet::BIN_PATH
          )
          assert_equal(<<~OUT, out)
            No errors! Great job.
          OUT
          assert(status)
          assert_equal(0, exit_code)
        end
      end
    end
  end
end
