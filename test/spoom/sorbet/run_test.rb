# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Sorbet
    class RunTest < TestWithProject
      def setup
        @project.write!("test.rb")
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
