# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Tests
    module Plugins
      class RSpecTest < TestWithProject
        extend T::Sig

        def test_match_context
          context = Context.mktmp!
          refute(RSpec.match_context?(context))

          context.write!("spec/foo_spec.rb", "")
          assert(RSpec.match_context?(context))
        end

        def test_test_files
          context = Context.mktmp!
          assert_empty(RSpec.test_files(context))

          context.write!("lib/foo.rb", "")
          context.write!("spec/test_helper.rb", "")
          context.write!("spec/foo_spec.rb", "")
          context.write!("spec/foo/bar_spec.rb", "")
          context.write!("test/foo/bar_test.rb", "")

          assert_equal(
            [
              "spec/foo/bar_spec.rb",
              "spec/foo_spec.rb",
            ],
            RSpec.test_files(context).sort_by(&:path).map(&:path),
          )
        end
      end
    end
  end
end
