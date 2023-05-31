# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class RubyTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

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

        def test_alive_trys
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

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugins: [Plugins::Ruby.new])
        end
      end
    end
  end
end
