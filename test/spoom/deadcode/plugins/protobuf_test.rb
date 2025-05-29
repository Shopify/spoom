# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ProtobufTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_definitions_in_protobuf_files
          @project.write!("lib/protobuf/proto/foo.rb", <<~RB)
          module FooModule
            class FooClass
              FOO_CONSTANT = 1
              def foo_method; end
            end
          end
          RB

          @project.write!("lib/tasks/bar.rb", <<~RB)
          module BarModule
            class BarClass
              BAR_CONSTANT = 1
              def bar_method; end
            end
          end
          RB

          index = index_with_plugins
          assert_ignored(index, "FooClass")
          assert_ignored(index, "FooModule")
          assert_ignored(index, "foo_method")
          assert_ignored(index, "FOO_CONSTANT")

          assert_dead(index, "BarClass")
          assert_dead(index, "BarModule")
          assert_dead(index, "bar_method")
          assert_dead(index, "BAR_CONSTANT")
        end

        private

        #: -> Deadcode::Index
        def index_with_plugins
          deadcode_index(plugin_classes: [Plugins::Protobuf])
        end
      end
    end
  end
end
