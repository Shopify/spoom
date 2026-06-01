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

        def test_callback_conditions_with_symbol_references
          @project.write!("app/models/my_model.rb", <<~RB)
            class MyModel
              after_create :notify, if: :type_updated?
              after_update :send_email, unless: :skip_notifications?
              before_save :normalize_data

              # These should be marked as used
              def type_updated?; end
              def skip_notifications?; end
              def notify; end
              def send_email; end
              def normalize_data; end

              # This should be marked as dead
              def unused_method; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "notify")
          assert_alive(index, "type_updated?")
          assert_alive(index, "send_email")
          assert_alive(index, "skip_notifications?")
          assert_alive(index, "normalize_data")
          assert_dead(index, "unused_method")
        end

        def test_callback_with_multiple_conditions
          @project.write!("app/models/my_model.rb", <<~RB)
            class MyModel
              after_commit :send_notification, if: :should_notify?, unless: :notifications_disabled?

              def send_notification; end
              def should_notify?; end
              def notifications_disabled?; end
              def unused_condition?; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "send_notification")
          assert_alive(index, "should_notify?")
          assert_alive(index, "notifications_disabled?")
          assert_dead(index, "unused_condition?")
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

        #: -> Index
        def index_with_plugins
          deadcode_index(plugin_classes: [ActiveRecord])
        end
      end
    end
  end
end
