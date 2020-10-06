# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class VersionTest < Minitest::Test
      include Spoom::TestHelper

      def test_return_nil_if_srb_not_installed
        project = spoom_project("test_return_nil_if_srb_not_installed")
        project.gemfile("")
        Bundler.with_clean_env do
          version = Spoom::Sorbet.srb_version(path: project.path, capture_err: true)
          assert_nil(version)
        end
        project.destroy
      end

      def test_return_version_string
        project = spoom_project("test_return_version_string")
        project.sorbet_config(".")
        version = Spoom::Sorbet.srb_version(path: project.path)
        assert_match(/\d\.\d\.\d{4}/, version)
        project.destroy
      end
    end
  end
end
