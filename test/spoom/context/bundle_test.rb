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

        res = context.bundle("install")
        assert_empty(res.out)
        assert_equal("Could not locate Gemfile\n", res.err)
        refute(res.status)

        context.write_gemfile!(<<~GEMFILE)
          source "https://rubygems.org"

          gem "ansi"
        GEMFILE

        res = context.bundle("install")
        assert(res.status)

        context.destroy!
      end
    end
  end
end
