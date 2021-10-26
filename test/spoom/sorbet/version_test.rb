# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class VersionTest < Minitest::Test
      include Spoom::TestHelper

      def setup
        @project = spoom_project
      end

      def teardown
        @project.destroy
      end

      def test_srb_version_return_nil_if_srb_not_installed
        @project.gemfile("")
        Bundler.with_unbundled_env do
          version = Spoom::Sorbet.srb_version(path: @project.path, capture_err: true)
          assert_nil(version)
        end
      end

      def test_srb_version_return_version_string
        version = Spoom::Sorbet.srb_version(path: @project.path)
        version = censor_sorbet_version(version) if version
        assert_equal("X.X.XXXX", version)
      end

      def test_version_from_gemfile_lock_return_nil_if_no_gemfile_lock
        version = Spoom::Sorbet.version_from_gemfile_lock(path: @project.path)
        assert_nil(version)
      end

      def test_version_from_gemfile_lock_return_nil_if_gemfil_lock_does_not_contain_sorbet
        @project.write("Gemfile.lock", "")
        version = Spoom::Sorbet.version_from_gemfile_lock(path: @project.path)
        assert_nil(version)
      end

      def test_version_from_gemfile_lock_return_sorbet_version
        @project.write("Gemfile.lock", <<~STR)
          PATH
            remote: .
            specs:
              test (1.0.0)
                sorbet (~> 0.5.5)
                sorbet-runtime

          GEM
            remote: https://rubygems.org/
            specs:
              sorbet (0.5.5001)
                sorbet-static (= 0.X.XXXX)
              sorbet-runtime (0.5.5002)
              sorbet-static (0.5.5003)

          PLATFORMS
            ruby

          DEPENDENCIES
            bundler (~> 1.17)
            test!

          BUNDLED WITH
             1.17.3
        STR
        assert_equal("0.5.5001", Spoom::Sorbet.version_from_gemfile_lock(gem: "sorbet", path: @project.path))
        assert_equal("0.5.5002", Spoom::Sorbet.version_from_gemfile_lock(gem: "sorbet-runtime", path: @project.path))
        assert_equal("0.5.5003", Spoom::Sorbet.version_from_gemfile_lock(gem: "sorbet-static", path: @project.path))
      end
    end
  end
end
