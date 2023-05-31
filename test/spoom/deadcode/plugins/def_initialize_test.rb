# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class DefInitializeTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_active_job_methods_based_on_path
          @project.write!("foo.rb", <<~RB)
            def initialize; end
            def foo; end

            class Foo
              def initialize(x); end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "initialize")
          refute_ignored(index, "foo")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugins: [Plugins::DefInitialize.new])
        end
      end
    end
  end
end
