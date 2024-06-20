# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class CustomTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_using_custom_plugins
          @project.write!("foo.rb", <<~RB)
            class Foo
              def foo1; end
              def foo2; end
              def foo3; end
            end

            class Bar; end
            class Baz; end
          RB

          @project.write!("#{Deadcode::DEFAULT_CUSTOM_PLUGINS_PATH}/plugin1.rb", <<~RB)
            class CustomPlugin1 < Spoom::Deadcode::Plugins::Base
              ignore_classes_named("Bar")
            end
          RB

          @project.write!("#{Deadcode::DEFAULT_CUSTOM_PLUGINS_PATH}/plugin2.rb", <<~RB)
            class CustomPlugin2 < Spoom::Deadcode::Plugins::Base
              ignore_methods_named("foo1", "foo2")
            end
          RB

          index = index_with_plugins(@project)
          refute_ignored(index, "Foo")
          assert_ignored(index, "Bar")
          refute_ignored(index, "Baz")
          assert_ignored(index, "foo1")
          assert_ignored(index, "foo2")
          refute_ignored(index, "foo3")
        end

        private

        sig { params(context: Context).returns(Deadcode::Index) }
        def index_with_plugins(context)
          plugins = Deadcode.load_custom_plugins(context)
          deadcode_index(plugin_classes: plugins)
        end
      end
    end
  end
end
