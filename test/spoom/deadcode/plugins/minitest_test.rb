# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class MinitestTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_minitest_classes_based_on_superclasses
          @project.write!("foo.rb", <<~RB)
            class C1Test < Minitest::Test; end
          RB

          @project.write!("test/foo.rb", <<~RB)
            class C2Test < ::Minitest::Test; end
          RB

          @project.write!("test/foo_test.rb", <<~RB)
            class C3Test < ::Minitest::Test; end
            class C4Test < C3Test; end
            class C5Test; end
          RB

          index = index_with_plugins
          assert_ignored(index, "C1Test")
          assert_ignored(index, "C2Test")
          assert_alive(index, "C3Test")
          assert_ignored(index, "C4Test")
          refute_ignored(index, "C5Test")
        end

        def test_ignore_minitest_methods
          @project.write!("test/foo_test.rb", <<~RB)
            class FooTest
              def after_all; end
              def around; end
              def around_all; end
              def before_all; end
              def setup; end
              def teardown; end
              def test_something; end

              def some_other_test; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "after_all")
          assert_ignored(index, "around")
          assert_ignored(index, "around_all")
          assert_ignored(index, "before_all")
          assert_ignored(index, "setup")
          assert_ignored(index, "teardown")
          assert_ignored(index, "test_something")
          refute_ignored(index, "some_other_test")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugin_classes: [Plugins::Minitest])
        end
      end
    end
  end
end
