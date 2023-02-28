# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Sorbet
    class VersionTest < TestWithProject
      def test_srb_version_return_nil_if_srb_not_installed
        @project.write_gemfile!("")
        Bundler.with_unbundled_env do
          version = Spoom::Sorbet.srb_version(path: @project.absolute_path, capture_err: true)
          assert_nil(version)
        end
      end

      def test_srb_version_return_version_string
        version = Spoom::Sorbet.srb_version(path: @project.absolute_path)
        version = censor_sorbet_version(version) if version
        assert_equal("X.X.XXXX", version)
      end
    end
  end
end
