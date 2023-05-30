# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Context
    class BundleTest < Minitest::Test
      def test_context_gemfile
        context = Context.mktmp!
        context.write_gemfile!("CONTENTS")
        assert(context.file?("Gemfile"))
        assert_equal("CONTENTS", context.read_gemfile)
        context.destroy!
      end

      def test_context_gemfile_lock
        context = Context.mktmp!
        context.write!("Gemfile.lock", "CONTENTS")
        assert_equal("CONTENTS", context.read_gemfile_lock)
        context.destroy!
      end

      def test_context_bundle
        context = Context.mktmp!

        res = context.bundle("-v")
        assert(res.status)

        res = context.bundle("-v", version: "9999999999.99999.999")
        refute(res.status)

        context.destroy!
      end

      def test_context_bundle_install!
        context = Context.mktmp!

        res = context.bundle_install!
        assert_empty(res.out)
        assert_equal("Could not locate Gemfile\n", res.err)
        refute(res.status)

        context.write_gemfile!(<<~GEMFILE)
          source "https://rubygems.org"

          gem "ansi"
        GEMFILE

        res = context.bundle_install!
        assert(res.status)

        context.destroy!
      end

      def test_context_read_gemfile_lock_specs_return_empty_array_if_no_gemfile_lock
        context = Context.mktmp!
        assert_empty(context.gemfile_lock_specs)
        context.destroy!
      end

      def test_context_read_gemfile_lock_specs_return_specs
        context = Context.mktmp!
        context.write!("Gemfile.lock", <<~GEMFILE_LOCK)
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
        GEMFILE_LOCK

        assert_equal(
          [
            ["sorbet", "0.5.5001"],
            ["sorbet-runtime", "0.5.5002"],
            ["sorbet-static", "0.5.5003"],
            ["test", "1.0.0"],
          ],
          context.gemfile_lock_specs.values.sort_by(&:name).map { |spec| [spec.name, spec.version.to_s] },
        )
        context.destroy!
      end

      def test_context_gem_version_from_gemfile_lock_return_nil_if_no_gemfile_lock
        context = Context.mktmp!
        version = context.gem_version_from_gemfile_lock("sorbet")
        assert_nil(version)
      end

      def test_version_from_gemfile_lock_return_nil_if_gemfil_lock_does_not_contain_sorbet
        context = Context.mktmp!
        context.write!("Gemfile.lock", "")
        version = context.gem_version_from_gemfile_lock("sorbet")
        assert_nil(version)
      end

      def test_version_from_gemfile_lock_return_sorbet_version
        context = Context.mktmp!
        context.write!("Gemfile.lock", <<~STR)
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
        assert_equal(
          "0.5.5001",
          context.gem_version_from_gemfile_lock("sorbet"),
        )
        assert_equal(
          "0.5.5002",
          context.gem_version_from_gemfile_lock("sorbet-runtime"),
        )
        assert_equal(
          "0.5.5003",
          context.gem_version_from_gemfile_lock("sorbet-static"),
        )
      end
    end
  end
end
