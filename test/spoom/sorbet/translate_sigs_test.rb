# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class TranslateSigsTest < Minitest::Test
      def test_empty
        contents = ""
        assert_equal(contents, TranslateSigs.rbi_to_rbs(contents))
      end

      def test_no_sigs
        contents = <<~RBI
          class A
            def foo; end
          end
        RBI

        assert_equal(contents, TranslateSigs.rbi_to_rbs(contents))
      end

      def test_top_level_sig
        contents = <<~RBI
          # typed: true

          sig { params(a: Integer, b: Integer).returns(Integer) }
          def foo(a, b)
            a + b
          end
        RBI

        assert_equal(<<~RBS, TranslateSigs.rbi_to_rbs(contents))
          # typed: true

          #: (Integer a, Integer b) -> Integer
          def foo(a, b)
            a + b
          end
        RBS
      end

      def test_method_sigs
        contents = <<~RBI
          class A
            sig { params(a: Integer).void }
            def initialize(a)
              @a = a
            end

            sig { returns(Integer) }
            def a
              @a
            end
          end
        RBI

        assert_equal(<<~RBS, TranslateSigs.rbi_to_rbs(contents))
          class A
            #: (Integer a) -> void
            def initialize(a)
              @a = a
            end

            #: -> Integer
            def a
              @a
            end
          end
        RBS
      end

      def test_singleton_method_sigs
        contents = <<~RBI
          class A
            sig { returns(Integer) }
            def self.foo
              42
            end
          end
        RBI

        assert_equal(<<~RBS, TranslateSigs.rbi_to_rbs(contents))
          class A
            #: -> Integer
            def self.foo
              42
            end
          end
        RBS
      end

      def test_attr_sigs
        contents = <<~RBI
          class A
            sig { returns(Integer) }
            attr_accessor :a

            sig { returns(Integer) }
            attr_reader :b, :c

            sig { params(d: Integer).void }
            attr_writer :d, :e
          end
        RBI

        assert_equal(<<~RBS, TranslateSigs.rbi_to_rbs(contents))
          class A
            #: Integer
            attr_accessor :a

            #: Integer
            attr_reader :b, :c

            #: Integer
            attr_writer :d, :e
          end
        RBS
      end
    end
  end
end
