# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class RubocopTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_rubocop_constants
          @project.write!("foo.rb", <<~RB)
            MSG = "indexed"
            RESTRICT_ON_SEND = ["indexed"]

            class Foo
              MSG = "indexed"
              RESTRICT_ON_SEND = ["indexed"]
            end

            class SomeCop < RuboCop::Cop::Cop
              MSG = "ignored"
              RESTRICT_ON_SEND = ["ignored"]

              class Foo
                MSG = "indexed"
                RESTRICT_ON_SEND = ["indexed"]
              end
            end
          RB

          assert_equal(
            [
              "foo.rb:10:2-10:17",
              "foo.rb:11:2-11:32",
            ],
            ignored_locations(index_with_plugins).map(&:to_s),
          )
        end

        def test_ignore_rubocop_cop_cop_methods
          @project.write!("foo.rb", <<~RB)
            class SomeCop < RuboCop::Cop::Cop
              def on_send(node); end
              def something_else; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "on_send")
          assert_dead(index, "something_else")
        end

        def test_ignore_rubocop_cop_base_methods
          @project.write!("foo.rb", <<~RB)
            class SomeCop < ::RuboCop::Cop::Base
              def on_send(node); end
              def something_else; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "on_send")
          assert_dead(index, "something_else")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugin_classes: [Plugins::Rubocop])
        end

        sig { params(index: Deadcode::Index).returns(T::Array[Location]) }
        def ignored_locations(index)
          index.all_definitions.select(&:constant?).select(&:ignored?).map(&:location)
        end
      end
    end
  end
end
