# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class NamespacesTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_namespaces
          @project.write!("foo.rb", <<~RB)
            class Dead1; end

            class Dead2
              # Comment
            end

            class Dead3
              # Comment

              # Comment

              # Comment
            end

            class Alive1
              class SomeClass; end
            end

            module Alive2
              class SomeClass; end
            end

            class Alive3
              def some_method; end
            end

            class Alive4
              def self.some_method; end
            end

            class Alive5
              CONST = 42
            end

            class Alive6
              ::CONST = 42
            end

            class Alive7
              CONST1::CONST2 = 42
            end

            class Alive8
              class << self; end
            end
          RB

          index = index_with_plugins
          refute_ignored(index, "Dead1")
          refute_ignored(index, "Dead2")
          refute_ignored(index, "Dead3")
          assert_ignored(index, "Alive1")
          assert_ignored(index, "Alive2")
          assert_ignored(index, "Alive3")
          assert_ignored(index, "Alive4")
          assert_ignored(index, "Alive5")
          assert_ignored(index, "Alive6")
          assert_ignored(index, "Alive7")
          assert_ignored(index, "Alive8")
        end

        private

        #: -> Deadcode::Index
        def index_with_plugins
          deadcode_index(plugin_classes: [Plugins::Namespaces])
        end
      end
    end
  end
end
