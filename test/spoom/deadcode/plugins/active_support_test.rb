# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ActiveSupportTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def setup
          @project.write!("test/foo_test.rb", <<~RB)
            class FooTest < ActiveSupport::TestCase
              setup(:alive1, :alive2)
              teardown(:alive3)

              def alive1; end
              def alive2; end
              def alive3; end
              def dead; end
            end
          RB
        end

        def test_ignore_minitest_setup_and_teardown_with_symbols
          index = index_with_plugins
          assert_alive(index, "alive1")
          assert_alive(index, "alive2")
          assert_alive(index, "alive3")
          assert_dead(index, "dead")
        end

        def test_ignore_test_class_definition
          assert_ignored(index_with_plugins, "FooTest")
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
