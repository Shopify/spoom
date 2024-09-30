# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class RubyTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_initialize
          @project.write!("foo.rb", <<~RB)
            def initialize; end
            def foo; end

            class Foo
              def initialize(x); end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "initialize")
          refute_ignored(index, "foo")
        end

        def test_ignore_hooks
          @project.write!("foo.rb", <<~RB)
            def extended; end
            def included; end
            def method_missing; end
            def prepended; end
          RB

          index = index_with_plugins
          assert_ignored(index, "extended")
          assert_ignored(index, "included")
          assert_ignored(index, "method_missing")
          assert_ignored(index, "prepended")
        end

        def test_alive_sends
          @project.write!("foo.rb", <<~RB)
            send(:alive1)
            send :alive2, :dead, nil

            __send__(:alive3)
            __send__ :alive4


            def alive1; end
            def alive2; end
            def alive3; end
            def alive4; end

            def dead; end
          RB

          index = index_with_plugins
          assert_alive(index, "alive1")
          assert_alive(index, "alive2")
          assert_alive(index, "alive3")
          assert_alive(index, "alive4")
          assert_dead(index, "dead")
        end

        def test_alive_tries
          @project.write!("foo.rb", <<~RB)
            try(:alive1)
            try :alive2, :dead, nil

            def alive1; end
            def alive2; end

            def dead; end
          RB

          index = index_with_plugins
          assert_alive(index, "alive1")
          assert_alive(index, "alive2")
          assert_dead(index, "dead")
        end

        def test_alive_aliases
          @project.write!("foo.rb", <<~RB)
            def dead1; end
            def alive1; end

            alias_method "dead1", "alive1"

            def dead2; end
            def alive2; end

            alias_method :dead1, :alive2
          RB

          index = index_with_plugins
          assert_alive(index, "alive1")
          assert_alive(index, "alive2")
          assert_dead(index, "dead1")
          assert_dead(index, "dead2")
        end

        def test_alive_constants_with_const_defined?
          @project.write!("foo.rb", <<~RB)
            ALIVE1 = 1
            ALIVE2 = 2

            DEAD = 42

            Object.const_defined?(:ALIVE1)
            Object.const_defined?("ALIVE2")
          RB

          index = index_with_plugins
          assert_alive(index, "ALIVE1")
          assert_alive(index, "ALIVE2")
          assert_dead(index, "DEAD")
        end

        def test_alive_constants_with_const_get
          @project.write!("foo.rb", <<~RB)
            ALIVE1 = 1
            ALIVE2 = 2
            ALIVE3 = 3
            ALIVE4 = 4
            ALIVE5 = 5
            ALIVE6 = 6

            DEAD = 42

            Object.const_get(:ALIVE1)
            Object.const_get("ALIVE2")
            Object.const_get("::ALIVE3")
            Object.const_get("::ALIVE4::ALIVE5::ALIVE6")
          RB

          index = index_with_plugins
          assert_alive(index, "ALIVE1")
          assert_alive(index, "ALIVE2")
          assert_alive(index, "ALIVE3")
          assert_alive(index, "ALIVE4")
          assert_alive(index, "ALIVE5")
          assert_alive(index, "ALIVE6")
          assert_dead(index, "DEAD")
        end

        def test_alive_constants_with_const_source_location
          @project.write!("foo.rb", <<~RB)
            ALIVE1 = 1
            ALIVE2 = 2

            DEAD = 42

            Object.const_source_location('ALIVE1')
            Object.const_source_location("ALIVE2")
          RB

          index = index_with_plugins
          assert_alive(index, "ALIVE1")
          assert_alive(index, "ALIVE2")
          assert_dead(index, "DEAD")
        end

        def test_alive_methods_with_method
          @project.write!("foo.rb", <<~RB)
            def alive1; end
            def alive2; end

            def dead; end

            method :alive1
            [].map(&method(:alive2))
          RB

          index = index_with_plugins
          assert_alive(index, "alive1")
          assert_alive(index, "alive2")
          assert_dead(index, "dead")
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugin_classes: [Plugins::Ruby])
        end
      end
    end
  end
end
