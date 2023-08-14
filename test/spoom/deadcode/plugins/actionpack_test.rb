# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ActionPackTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_actionpack_controllers
          @project.write!("app/controllers/foo.rb", <<~RB)
            class FooController
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "FooController")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugins: [Plugins::ActionPack.new])
        end
      end
    end
  end
end
