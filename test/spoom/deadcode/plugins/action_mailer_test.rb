# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ActionMailerTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_dead_mailer_callbacks
          @project.write!("app/models/my_model.rb", <<~RB)
            class MyMailer < ApplicationMailer
              after_action :method1
              around_action :method2
              before_action :method3

              def method1; end
              def method2; end
              def method3; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "method1")
          assert_alive(index, "method2")
          assert_alive(index, "method3")
        end

        private

        sig { returns(Index) }
        def index_with_plugins
          deadcode_index(plugins: [ActionMailer.new])
        end
      end
    end
  end
end
