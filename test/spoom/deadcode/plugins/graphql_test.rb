# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class GraphQLTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_graphql_classes
          @project.write!("foo.rb", <<~RB)
            class Class1 < GraphQL::Schema::Object; end
            class Class2 < ::GraphQL::Schema::Enum; end
            class Class3; end
          RB

          index = index_with_plugins
          assert_ignored(index, "Class1")
          assert_ignored(index, "Class2")
          refute_ignored(index, "Class3")
        end

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

        def test_ignore_graphql_fields
          @project.write!("foo.rb", <<~RB)
            class SomeClass
              field :field1, String, null: false

              def field1; end

              field :field2, String, null: false, resolver_method: :my_resolver

              def my_resolver; end

              def dead; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "field1")
          assert_alive(index, "my_resolver")
          assert_dead(index, "dead")
        end

        def test_alive_argument_prepare
          @project.write!("foo.rb", <<~RB)
            class SomeMutation
              argument :input, String, required: true, prepare: :transform_input

              def transform_input(value); end
              def dead; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "transform_input")
          assert_dead(index, "dead")
        end

        def test_alive_builds
          @project.write!("foo.rb", <<~RB)
            class SomeMutation
              builds :thing

              def build_thing; end
              def dead; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "build_thing")
          assert_dead(index, "dead")
        end

        def test_alive_field_method
          @project.write!("foo.rb", <<~RB)
            class SomeType
              field :name, String, null: false, method: :custom_name

              def custom_name; end
              def dead; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "custom_name")
          assert_dead(index, "dead")
        end

        def test_alive_argument_method
          @project.write!("foo.rb", <<~RB)
            class SomeMutation
              argument :input, String, required: true, method: :custom_input

              def custom_input; end
              def dead; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "custom_input")
          assert_dead(index, "dead")
        end

        def test_ignore_method_splats
          @project.write!("foo.rb", <<~RB)
            field(:field1)
            field(*args, **kwargs) {}

            def field1; end
          RB

          index = index_with_plugins
          assert_alive(index, "field1")
        end

        private

        #: -> Deadcode::Index
        def index_with_plugins
          deadcode_index(plugin_classes: [Plugins::GraphQL])
        end
      end
    end
  end
end
