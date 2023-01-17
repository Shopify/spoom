# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Sorbet
    class RunTest < TestWithProject
      def setup
        @project.write!("test.rb")
      end

      def test_run_srb_from_bundler
        @project.write_gemfile!(<<~GEM)
          source 'https://rubygems.org'
          gem 'sorbet'
        GEM
        Bundler.with_unbundled_env do
          result = @project.bundle_install!
          assert(result.status)

          result = Spoom::Sorbet.srb(path: @project.absolute_path, capture_err: true)
          assert_equal(<<~OUT, result.err)
            No errors! Great job.
          OUT
          assert(result.status)
          assert_equal(0, result.exit_code)
        end
      end

      def test_run_srb_from_bundler_not_found
        @project.write_gemfile!("source 'https://rubygems.org'")
        Bundler.with_unbundled_env do
          result = @project.bundle_install!
          assert(result.status)

          result = Spoom::Sorbet.srb(path: @project.absolute_path, capture_err: true)
          refute(result.status)
          refute_equal(0, result.exit_code)
        end
      end

      def test_run_sorbet_from_path
        Bundler.with_unbundled_env do
          result = Spoom::Sorbet.srb(
            "-h",
            path: @project.absolute_path,
            capture_err: true,
            sorbet_bin: Spoom::Sorbet::BIN_PATH,
          )
          assert_equal(<<~OUT, result.err)
            Typechecker for Ruby
            Usage:
              sorbet [OPTION...] <path 1> <path 2> ...

              -e string      Parse an inline ruby string (default: "")
              -q, --quiet    Silence all non-critical errors
              -v, --verbose  Verbosity level [0-3]
              -h             Show short help
                  --help     Show long help
                  --version  Show version

          OUT
          assert(result.status)
          assert_equal(0, result.exit_code)
        end
      end

      def test_run_sorbet_tc_from_path
        Bundler.with_unbundled_env do
          result = Spoom::Sorbet.srb_tc(
            path: @project.absolute_path,
            capture_err: true,
            sorbet_bin: Spoom::Sorbet::BIN_PATH,
          )
          assert_equal(<<~OUT, result.err)
            No errors! Great job.
          OUT
          assert(result.status)
          assert_equal(0, result.exit_code)
        end
      end

      def test_run_sorbet_metrics_from_path
        Bundler.with_unbundled_env do
          result = Spoom::Sorbet.srb_metrics(
            path: @project.absolute_path,
            sorbet_bin: Spoom::Sorbet::BIN_PATH,
          )

          assert_instance_of(Hash, result)
          refute_empty(result)
        end
      end

      def test_sorbet_raises_when_killed
        Bundler.with_unbundled_env do
          mock_result = ExecResult.new(
            out: "out",
            err: "err",
            status: false,
            exit_code: Spoom::Sorbet::KILLED_CODE,
          )

          Spoom.stub(:exec, mock_result) do
            assert_raises(Spoom::Sorbet::Error::Killed, "Sorbet was killed.") do
              Spoom::Sorbet.srb("-e foo")
            end
          end
        end
      end

      def test_sorbet_raises_on_sefault
        Bundler.with_unbundled_env do
          mock_result = ExecResult.new(
            out: "out",
            err: "err",
            status: false,
            exit_code: Spoom::Sorbet::SEGFAULT_CODE,
          )

          Spoom.stub(:exec, mock_result) do
            assert_raises(Spoom::Sorbet::Error::Segfault, "Sorbet segfaulted.") do
              Spoom::Sorbet.srb("-e foo")
            end
          end
        end
      end
    end
  end
end
