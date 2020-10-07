# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class VersionTest < Minitest::Test
      include Spoom::TestHelper

      def setup
        @project = spoom_project("test_version")
      end

      def teardown
        @project.destroy
      end

      def test_srb_version_return_nil_if_srb_not_installed
        @project.gemfile("")
        Bundler.with_clean_env do
          version = Spoom::Sorbet.srb_version(path: @project.path, capture_err: true)
          assert_nil(version)
        end
      end

      def test_srb_version_return_version_string
        @project.sorbet_config(".")
        version = Spoom::Sorbet.srb_version(path: @project.path)
        assert_match(/\d\.\d\.\d{4}/, version)
      end
    end
  end
end
