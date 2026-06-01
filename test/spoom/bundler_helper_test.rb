# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class BundlerHelperTest < Minitest::Test
    def test_gem_requirement_from_real_bundle_returns_gem_requirement_string
      gem_from_spoom_bundle = "tapioca"
      gem_requirement = BundlerHelper.gem_requirement_from_real_bundle(gem_from_spoom_bundle)

      assert_match(/^gem "#{gem_from_spoom_bundle}", "= .+"$/, gem_requirement)
    end

    def test_raises_if_gem_not_found_in_bundle
      assert_raises(RuntimeError) do
        BundlerHelper.gem_requirement_from_real_bundle("not-real")
      end
    end
  end
end
