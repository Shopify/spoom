# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class RSpecTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_rspec_methods
          @project.write!("spec/foo_spec.rb", <<~RB)
            class FooSpec
              def before_setup; end
              def after_teardown; end
              def foo; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "before_setup")
          assert_ignored(index, "after_teardown")
          refute_ignored(index, "foo")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugins: [Plugins::RSpec.new])
        end
      end
    end
  end
end
