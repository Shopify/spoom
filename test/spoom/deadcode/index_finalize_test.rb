# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    class IndexFinalizeTest < Spoom::TestWithProject
      include Test::Helpers::DeadcodeHelper

      def test_index_deadcode_constants
        @project.write!("foo.rb", <<~RB)
          class Foo
            DEAD1 = 42

            def foo
              puts ALIVE1
            end
          end

          ALIVE1 = 42
          ALIVE2 = 42
          DEAD2 = 42

          puts ALIVE2
          Foo.foo
        RB

        index = deadcode_index
        assert_alive(index, "ALIVE1")
        assert_alive(index, "ALIVE2")
        assert_dead(index, "DEAD1")
        assert_dead(index, "DEAD2")
      end

      def test_index_deadcode_classes
        @project.write!("foo.rb", <<~RB)
          class ALIVE1
            def initialize
              @x = ALIVE2.new
            end

            class DEAD1; end
          end

          class ALIVE2; end
          class DEAD2; end

          ALIVE1.new
        RB

        index = deadcode_index
        assert_alive(index, "ALIVE1")
        assert_alive(index, "ALIVE2")
        assert_dead(index, "DEAD1")
        assert_dead(index, "DEAD2")
      end

      def test_index_deadcode_modules
        @project.write!("foo.rb", <<~RB)
          module ALIVE1
            include ALIVE2

            module DEAD1; end
          end

          module ALIVE2; end
          module DEAD2; end

          puts ALIVE1.ancestors
        RB

        index = deadcode_index
        assert_alive(index, "ALIVE1")
        assert_alive(index, "ALIVE2")
        assert_dead(index, "DEAD1")
        assert_dead(index, "DEAD2")
      end

      def test_index_deadcode_methods
        @project.write!("foo.rb", <<~RB)
          def dead1; end

          def alive1
            alive2
          end

          def alive2; end
          def dead2; end

          alive1
        RB

        index = deadcode_index
        assert_alive(index, "alive1")
        assert_alive(index, "alive2")
        assert_dead(index, "dead1")
        assert_dead(index, "dead2")
      end

      def test_index_deadcode_aref
        @project.write!("foo.rb", <<~RB)
          def []; end
          def []=; end
        RB

        index = deadcode_index
        assert_dead(index, "[]")
        assert_dead(index, "[]=")

        @project.write!("foo.rb", <<~RB)
          def []; end
          def []=; end

          self[:foo]
          self[:foo] = 42
        RB

        index = deadcode_index
        assert_alive(index, "[]")
        assert_alive(index, "[]=")
      end

      def test_index_deadcode_operators
        @project.write!("foo.rb", <<~RB)
          def <=>(x); end
          def -(x); end
          def <<(x); end

          self < 42
          self - 42
          self << 42
        RB

        index = deadcode_index
        assert_alive(index, "<=>")
        assert_alive(index, "-")
        assert_alive(index, "<<")
      end

      def test_index_deadcode_aliases
        @project.write!("foo.rb", <<~RB)
          def dead; end
          def alive; end

          alias dead alive
        RB

        index = deadcode_index
        assert_alive(index, "alive")
        assert_dead(index, "dead")
      end
    end
  end
end
