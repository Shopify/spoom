# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class RakeTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_rake_constants
          @project.write!("foo.rb", <<~RB)
            APP_RAKEFILE = "foo"
          RB

          index = index_with_plugins
          assert_ignored(index, "APP_RAKEFILE")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugins: [Plugins::Rake.new])
        end
      end
    end
  end
end
