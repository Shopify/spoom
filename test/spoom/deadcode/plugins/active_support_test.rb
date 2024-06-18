# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ActiveSupportTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_minitest_setup_and_teardown_with_symbols
          @project.write!("test/foo_test.rb", <<~RB)
            class FooTest
              setup(:alive1, :alive2)
              teardown(:alive3)

              def alive1; end
              def alive2; end
              def alive3; end
              def dead; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "alive1")
          assert_alive(index, "alive2")
          assert_alive(index, "alive3")
          assert_dead(index, "dead")
        end

        private

        sig { returns(Index) }
        def index_with_plugins
          deadcode_index(plugin_classes: [ActiveSupport])
        end
      end
    end
  end
end
