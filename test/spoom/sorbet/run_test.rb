# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Sorbet
    class RunTest < TestWithProject
      def setup
        @project.write!("test.rb")
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
    end
  end
end
