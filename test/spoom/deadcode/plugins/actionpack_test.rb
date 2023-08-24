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
              def foo; end
            end

            module Bar
              def bar; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "FooController")
          assert_ignored(index, "foo")
          refute_ignored(index, "Bar")
          refute_ignored(index, "bar")
        end

        def test_dead_controller_callbacks
          @project.write!("app/controllers/my_controller.rb", <<~RB)
            class MyController < ApplicationController
              before_action MyFilter1
              around_action :method1
              after_action :method2, only: [:index, :show]
              skip_before_action :method3, only: [:index, :show]
              before_action { MyFilter2; method4 }
              after_action do MyFilter3; method5 end
              prepend_before_action :method6
              before_action :method7, if: :method8

              def method1; end
              def method2; end
              def method3; end
              def method4; end
              def method5; end
              def method6; end
              def method7; end
              def method8; end
            end

            class MyFilter1; end
            class MyFilter2; end
            class MyFilter3; end
          RB

          index = index_with_plugins
          assert_alive(index, "MyFilter1")
          assert_alive(index, "MyFilter2")
          assert_alive(index, "MyFilter3")
          assert_alive(index, "method1")
          assert_alive(index, "method2")
          assert_alive(index, "method3")
          assert_alive(index, "method4")
          assert_alive(index, "method5")
          assert_alive(index, "method6")
          assert_alive(index, "method7")
          assert_alive(index, "method8")
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
