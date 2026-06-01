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
          assert_ignored(index, "MyValidator")
          assert_ignored(index, "validate_each")
          refute_ignored(index, "another_method")
        end

        def test_ignore_persisted
          @project.write!("app/model/validators/my_validator.rb", <<~RB)
            class MyModel
              def persisted?; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "persisted?")
        end

        def test_dead_validation_callbacks
          @project.write!("app/models/my_model.rb", <<~RB)
            class MyModel
              validates_with MyValidator1
              validate :method1, :method2
              validate { method3 }
              validates :attr1, my_validator2: true
              validates! :attr2, my_validator3: true, my_validator4: true
              validates_each :attr3, :attr4, my_validator5: true
              validates :attr5, :my_validator6 => true
              validates :attr6, :"validators/my_validator7" => true
              validates :attr7, if: :method4
              validates :attr7, unless: :method5

              def method1; end
              def method2; end
              def method3; end
              def method4; end
              def method5; end
            end

            class MyValidator1; end
            class MyValidator2; end
            class MyValidator3; end
            class MyValidator4; end
            class MyValidator5; end
            class MyValidator6; end
          RB

          @project.write!("app/models/validators/my_validator7.rb", <<~RB)
            class MyValidator7; end
          RB

          index = index_with_plugins
          assert_alive(index, "MyValidator1")
          assert_alive(index, "MyValidator2")
          assert_alive(index, "MyValidator3")
          assert_alive(index, "MyValidator4")
          assert_alive(index, "MyValidator5")
          assert_alive(index, "MyValidator6")
          assert_alive(index, "MyValidator7")
          assert_alive(index, "method1")
          assert_alive(index, "method2")
          assert_alive(index, "method3")
          assert_alive(index, "method4")
          assert_alive(index, "method5")
        end

        def test_alive_nested_validation_option_symbols
          @project.write!("app/models/my_model.rb", <<~RB)
            class MyModel
              validates :attr1, inclusion: { in: :allowed_values }
              validates :attr2, numericality: { less_than: :max_value, greater_than: :min_value }
              validates :attr3, format: { with: :pattern_method }
              validates :attr4, exclusion: { in: :excluded_values }
              validates :attr5, numericality: { equal_to: :target_value, other_than: :avoid_value }
              validates :attr6, numericality: { less_than_or_equal_to: :upper_bound, greater_than_or_equal_to: :lower_bound }

              def allowed_values; end
              def max_value; end
              def min_value; end
              def pattern_method; end
              def excluded_values; end
              def target_value; end
              def avoid_value; end
              def upper_bound; end
              def lower_bound; end
              def dead_method; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "allowed_values")
          assert_alive(index, "max_value")
          assert_alive(index, "min_value")
          assert_alive(index, "pattern_method")
          assert_alive(index, "excluded_values")
          assert_alive(index, "target_value")
          assert_alive(index, "avoid_value")
          assert_alive(index, "upper_bound")
          assert_alive(index, "lower_bound")
          assert_dead(index, "dead_method")
        end

        def test_dead_serializer_attribute
          @project.write!("app/model/serializers/my_serializer.rb", <<~RB)
            class MySerializer < ActiveModel::Serializer
              attribute :def1
              attribute :def2, :def3

              def def1; end
              def def2; end
              def def3; end
              def def4; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "def1")
          assert_alive(index, "def2")
          assert_alive(index, "def3")
          assert_dead(index, "def4")
        end

        def test_dead_serializer_attributes
          @project.write!("app/model/serializers/my_serializer.rb", <<~RB)
            class MySerializer < ActiveModel::Serializer
              attributes :def1, :def2

              def def1; end
              def def2; end
              def def3; end
            end
          RB

          index = index_with_plugins
          assert_alive(index, "def1")
          assert_alive(index, "def2")
          assert_dead(index, "def3")
        end

        private

        #: -> Index
        def index_with_plugins
          deadcode_index(plugin_classes: [ActiveModel])
        end
      end
    end
  end
end
