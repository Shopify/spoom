# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class SigsTest < Minitest::Test
      # strip

      def test_strip_empty
        contents = ""
        assert_equal(contents, Sigs.strip(contents))
      end

      def test_strip_no_sigs
        contents = <<~RB
          class A
            def foo; end
          end
        RB

        assert_equal(contents, Sigs.strip(contents))
      end

      def test_strip_sigs
        contents = <<~RB
          class A
            sig { returns(Integer) }
            attr_accessor :a

            sig { void }
            def foo; end

            module B
              sig { void }
              sig { returns(Integer) }
              def bar; end
            end
          end
        RB

        assert_equal(<<~RB, Sigs.strip(contents))
          class A
            attr_accessor :a

            def foo; end

            module B
              def bar; end
            end
          end
        RB
      end

      # translate

      def test_translate_empty
        contents = ""
        assert_equal(contents, Sigs.rbi_to_rbs(contents))
      end

      def test_translate_no_sigs
        contents = <<~RBI
          class A
            def foo; end
          end
        RBI

        assert_equal(contents, Sigs.rbi_to_rbs(contents))
      end

      def test_translate_top_level_sig
        contents = <<~RBI
          # typed: true

          sig { params(a: Integer, b: Integer).returns(Integer) }
          def foo(a, b)
            a + b
          end
        RBI

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          # typed: true

          #: (Integer a, Integer b) -> Integer
          def foo(a, b)
            a + b
          end
        RBS
      end

      def test_translate_method_sigs
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

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
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

      def test_translate_method_sigs_with_annotations
        contents = <<~RBI
          sig(:final) { abstract.override(allow_incompatible: true).void }
          def foo; end
        RBI

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          # @final
          # @abstract
          # @override(allow_incompatible: true)
          #: -> void
          def foo; end
        RBS
      end

      def test_translate_singleton_method_sigs
        contents = <<~RBI
          class A
            sig { returns(Integer) }
            def self.foo
              42
            end
          end
        RBI

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          class A
            #: -> Integer
            def self.foo
              42
            end
          end
        RBS
      end

      def test_translate_attr_sigs
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

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
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
