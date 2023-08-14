# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ActiveModelTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_validation_class
          @project.write!("app/model/validators/my_validator.rb", <<~RB)
            class MyValidator < ActiveModel::EachValidator
              def validate_each(record, attribute, value); end
              def another_method; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "validate_each")
        end

        private

        sig { returns(Index) }
        def index_with_plugins
          deadcode_index(plugins: [ActiveModel.new])
        end
      end
    end
  end
end
