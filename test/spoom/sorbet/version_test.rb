# typed: true
# frozen_string_literal: true

require "pathname"

require_relative "../cli/cli_test_helper"

module Spoom
  module Sorbet
    class VersionTest < Minitest::Test
      include Spoom::Cli::TestHelper
      extend Spoom::Cli::TestHelper

      def project_path
        "#{Cli::TestHelper::TEST_PROJECTS_PATH}/project"
      end

      def test_return_nil_if_srb_not_installed
        Bundler.with_clean_env do
          version = Spoom::Sorbet.srb_version(
            path: "#{Cli::TestHelper::TEST_PROJECTS_PATH}/project_without_sorbet",
            capture_err: true,
          )
          assert_nil(version)
        end
      end

      def test_return_version_string
        Bundler.with_clean_env do
          version = Spoom::Sorbet.srb_version(path: "#{Cli::TestHelper::TEST_PROJECTS_PATH}/project")
          assert_equal("0.5.5808", version)
        end
      end
    end
  end
end
