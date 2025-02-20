# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class RailsTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_rails_app_path
          @project.write!("bin/rails", <<~RB)
            #!/usr/bin/env ruby

            APP_PATH = "."
            ENGINE_ROOT = "."
            ENGINE_PATH = "."
            FOO = 1
          RB

          index = index_with_plugins
          assert_ignored(index, "APP_PATH")
          assert_ignored(index, "ENGINE_ROOT")
          assert_ignored(index, "ENGINE_PATH")
          refute_ignored(index, "FOO")
        end

        def test_ignore_rails_helpers
          @project.write!("foo.rb", <<~RB)
            class SomeHelper; end
          RB

          @project.write!("app/helpers/foo.rb", <<~RB)
            class Foo
              def foo; end
            end

            module Bar; end
          RB

          index = index_with_plugins
          refute_ignored(index, "SomeHelper")
          assert_ignored(index, "Foo")
          refute_ignored(index, "foo")
          assert_ignored(index, "Bar")
        end

        private

        #: -> Deadcode::Index
        def index_with_plugins
          deadcode_index(plugin_classes: [Plugins::Rails])
        end
      end
    end
  end
end
