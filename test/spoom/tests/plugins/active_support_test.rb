# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Tests
    module Plugins
      class ActiveSupportTest < TestWithProject
        extend T::Sig

        def test_match_context
          context = Context.mktmp!
          refute(ActiveSupport.match_context?(context))

          context.write!("test/foo_test.rb", "")
          refute(ActiveSupport.match_context?(context))

          context.write!("config/application.rb", "")
          assert(ActiveSupport.match_context?(context))
        end

        def test_test_files
          context = Context.mktmp!
          assert_empty(ActiveSupport.test_files(context))

          context.write!("app/foo.rb", "")
          context.write!("test/test_helper.rb", "")
          context.write!("test/foo_test.rb", "")
          context.write!("test/foo/bar_test.rb", "")

          assert_equal(
            [
              "test/foo/bar_test.rb",
              "test/foo_test.rb",
            ],
            ActiveSupport.test_files(context).sort_by(&:path).map(&:path),
          )
        end
      end
    end
  end
end
