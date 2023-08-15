# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class BaseTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        class TestPlugin < Spoom::Deadcode::Plugins::Base
          ignore_methods_named(
            "name1",
            "name2",
            /^name_re.*/,
          )

          def on_define_accessor(indexer, definition)
            definition.ignored! if definition.name == "attr_reader1"
          end

          def on_define_class(indexer, definition)
            definition.ignored! if definition.name == "Class1"
          end

          def on_define_constant(indexer, definition)
            definition.ignored! if definition.name == "CONST1"
          end

          def on_define_method(indexer, definition)
            super

            definition.ignored! if definition.name == "method1"
          end

          def on_define_module(indexer, definition)
            definition.ignored! if definition.name == "Module1"
          end

          def on_send(indexer, send)
            return unless send.name == "dsl_method"
            return if send.args.empty?

            method_name = indexer.node_string(send.args.first).delete_prefix(":")
            indexer.reference_method(method_name, send.node)
          end
        end

        def test_ignore_method_by_names
          @project.write!("foo.rb", <<~RB)
            def name1; end
            def name2; end
            def name3; end
            def name_regexp1; end
            def name_regexp2; end
          RB

          index = index_with_plugins
          assert_ignored(index, "name1")
          assert_ignored(index, "name2")
          refute_ignored(index, "name3")
          assert_ignored(index, "name_regexp1")
          assert_ignored(index, "name_regexp2")
        end

        def test_on_define_accessor
          @project.write!("foo.rb", <<~RB)
            attr_reader :attr_reader1
            attr_reader :attr_reader2
          RB

          index = index_with_plugins
          assert_ignored(index, "attr_reader1")
          refute_ignored(index, "attr_reader2")
        end

        def test_on_define_class
          @project.write!("foo.rb", <<~RB)
            class Class1; end
            class Class2; end
          RB

          index = index_with_plugins
          assert_ignored(index, "Class1")
          refute_ignored(index, "Class2")
        end

        def test_on_define_constant
          @project.write!("foo.rb", <<~RB)
            CONST1 = 1
            CONST2 = 2
          RB

          index = index_with_plugins
          assert_ignored(index, "CONST1")
          refute_ignored(index, "CONST2")
        end

        def test_on_define_method
          @project.write!("foo.rb", <<~RB)
            def method1; end
            def method2; end
          RB

          index = index_with_plugins
          assert_ignored(index, "method1")
          refute_ignored(index, "method2")
        end

        def test_on_define_module
          @project.write!("foo.rb", <<~RB)
            module Module1; end
            module Module2; end
          RB

          index = index_with_plugins
          assert_ignored(index, "Module1")
          refute_ignored(index, "Module2")
        end

        def test_on_send
          @project.write!("foo.rb", <<~RB)
            dsl_method :method1
            dsl_method :method2

            def method1; end
            def method2; end
            def method3; end
          RB

          index = index_with_plugins
          assert_alive(index, "method1")
          assert_alive(index, "method2")
          assert_dead(index, "method3")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugins: [TestPlugin.new])
        end
      end
    end
  end
end
