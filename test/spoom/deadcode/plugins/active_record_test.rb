# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ActiveRecordTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_migration_classes
          @project.write!("db/migrate/20230101000000_create_model.rb", <<~RB)
            class CreateModel < ActiveRecord::Migration[7.0]
              def change; end
              def down; end
              def up; end
              def some_method; end
            end

            class SomeClass; end
            class SomeOtherClass < SomeClass; end
          RB

          index = index_with_plugins
          assert_ignored(index, "CreateModel")
          refute_ignored(index, "SomeOtherClass")
          refute_ignored(index, "SomeOtherClass")
          assert_ignored(index, "change")
          assert_ignored(index, "down")
          assert_ignored(index, "up")
          refute_ignored(index, "some_method")
        end

        def test_dead_record_callbacks
          @project.write!("app/models/my_model.rb", <<~RB)
            class MyModel
              after_commit :method1
              after_find :method2, if: Proc.new { medthod3 }

              def method1; end
              def method2; end
              def method3; end
            end

            class SomeClass; end
            class SomeOtherClass < SomeClass; end
          RB

          index = index_with_plugins
          assert_alive(index, "method1")
          assert_alive(index, "method2")
          assert_dead(index, "method3")
        end

        def test_dead_record_assign_attributes_assoc
          ActiveRecord::CRUD_METHODS.each do |method|
            @project.write!("app/models/my_model.rb", <<~RB)
              class MyModel
                def method1=; end
                def method2=; end
                def method3=; end
              end

              MyModel.#{method}(
                method1: "foo",
                method2: "bar",
              )
            RB

            index = index_with_plugins
            assert_alive(index, "method1=")
            assert_alive(index, "method2=")
            assert_dead(index, "method3=")
          end
        end

        def test_dead_record_assign_attributes_assoc_hash
          ActiveRecord::CRUD_METHODS.each do |method|
            @project.write!("app/models/my_model.rb", <<~RB)
              class MyModel
                def method1=; end
                def method2=; end
                def method3=; end
              end

              MyModel.#{method}({ method1: "foo", method2: "bar" })
            RB

            index = index_with_plugins
            assert_alive(index, "method1=")
            assert_alive(index, "method2=")
            assert_dead(index, "method3=")
          end
        end

        def test_dead_record_insert_all
          ["insert_all", "insert_all!", "upsert_all"].each do |method|
            @project.write!("app/models/my_model.rb", <<~RB)
              class MyModel
                def method1=; end
                def method2=; end
                def method3=; end
              end

              MyModel.#{method}([
                { method1: "foo", method2: "bar" }
              ])
            RB

            index = index_with_plugins
            assert_alive(index, "method1=")
            assert_alive(index, "method2=")
            assert_dead(index, "method3=")
          end
        end

        private

        sig { returns(Index) }
        def index_with_plugins
          deadcode_index(plugin_classes: [ActiveRecord])
        end
      end
    end
  end
end
