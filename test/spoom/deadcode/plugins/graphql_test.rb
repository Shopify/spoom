# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class GraphQLTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_graphql_methods
          @project.write!("foo.rb", <<~RB)
            class SomeClass
              def coerce_input; end
              def coerce_result; end
              def graphql_name; end
              def resolve_type; end
              def subscribed; end
              def unsubscribed; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "coerce_input")
          assert_ignored(index, "coerce_result")
          assert_ignored(index, "graphql_name")
          assert_ignored(index, "resolve_type")
          assert_ignored(index, "subscribed")
          assert_ignored(index, "unsubscribed")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugins: [Plugins::GraphQL.new])
        end
      end
    end
  end
end
