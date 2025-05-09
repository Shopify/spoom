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

      # translate RBI to RBS

      def test_translate_to_rbs_empty
        contents = ""
        assert_equal(contents, Sigs.rbi_to_rbs(contents))
      end

      def test_translate_to_rbs_no_sigs
        contents = <<~RB
          class A
            def foo; end
          end
        RB

        assert_equal(contents, Sigs.rbi_to_rbs(contents))
      end

      def test_translate_to_rbs_top_level_sig
        contents = <<~RB
          # typed: true

          sig { params(a: Integer, b: Integer).returns(Integer) }
          def foo(a, b)
            a + b
          end
        RB

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          # typed: true

          #: (Integer a, Integer b) -> Integer
          def foo(a, b)
            a + b
          end
        RBS
      end

      def test_translate_to_rbs_method_sigs
        contents = <<~RB
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
        RB

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

      def test_does_not_translate_to_rbs_abstract_methods
        contents = <<~RB
          sig { abstract.void }
          def foo; end
        RB

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          sig { abstract.void }
          def foo; end
        RBS
      end

      def test_translate_method_sigs_to_rbs_without_positional_names
        contents = <<~RBI
          class A
            sig { params(a: Integer, b: Integer, c: Integer, d: Integer, e: Integer, f: Integer).void }
            def initialize(a, b = 42, *c, d:, e: 42, **f); end
          end
        RBI

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents, positional_names: false))
          class A
            #: (Integer, ?Integer, *Integer, d: Integer, ?e: Integer, **Integer f) -> void
            def initialize(a, b = 42, *c, d:, e: 42, **f); end
          end
        RBS
      end

      def test_translate_to_rbs_method_sigs_with_annotations
        contents = <<~RB
          sig(:final) { overridable.override(allow_incompatible: true).void }
          def foo; end
        RB

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          # @final
          # @override(allow_incompatible: true)
          # @overridable
          #: -> void
          def foo; end
        RBS
      end

      def test_translate_to_rbs_method_sigs_without_runtime
        contents = <<~RB
          T::Sig::WithoutRuntime.sig { void }
          def foo; end
        RB

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          # @without_runtime
          #: -> void
          def foo; end
        RBS
      end

      def test_translate_to_rbs_singleton_method_sigs
        contents = <<~RB
          class A
            sig { returns(Integer) }
            def self.foo
              42
            end
          end
        RB

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          class A
            #: -> Integer
            def self.foo
              42
            end
          end
        RBS
      end

      def test_translate_to_rbs_attr_sigs
        contents = <<~RB
          class A
            sig { returns(Integer) }
            attr_accessor :a

            sig { returns(Integer) }
            attr_reader :b, :c

            sig { params(d: Integer).void }
            attr_writer :d, :e
          end
        RB

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

      def test_translate_to_rbs_attr_sigs_with_annotations
        contents = <<~RB
          sig(:final) { overridable.override(allow_incompatible: true).returns(Integer) }
          attr_accessor :foo
        RB

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          # @final
          # @override(allow_incompatible: true)
          # @overridable
          #: Integer
          attr_accessor :foo
        RBS
      end

      def test_translate_to_rbs_attr_sigs_without_runtime
        contents = <<~RB
          T::Sig::WithoutRuntime.sig { returns(Integer) }
          attr_accessor :foo
        RB

        assert_equal(<<~RBS, Sigs.rbi_to_rbs(contents))
          # @without_runtime
          #: Integer
          attr_accessor :foo
        RBS
      end

      # translate RBS to RBI

      def test_translate_to_rbi_empty
        contents = ""
        assert_equal(contents, Sigs.rbs_to_rbi(contents))
      end

      def test_translate_to_rbi_no_sigs
        contents = <<~RB
          class A
            def foo; end
          end
        RB

        assert_equal(contents, Sigs.rbs_to_rbi(contents))
      end

      def test_translate_to_rbi_top_level_sig
        contents = <<~RB
          # typed: true

          #: (Integer a, Integer b) -> Integer
          def foo(a, b)
            a + b
          end
        RB

        assert_equal(<<~RB, Sigs.rbs_to_rbi(contents))
          # typed: true

          sig { params(a: Integer, b: Integer).returns(Integer) }
          def foo(a, b)
            a + b
          end
        RB
      end

      def test_translate_to_rbi_method_sigs
        contents = <<~RB
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
        RB

        assert_equal(<<~RB, Sigs.rbs_to_rbi(contents))
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
        RB
      end

      def test_translate_to_rbi_method_sigs_with_annotations
        contents = <<~RB
          # @final
          # @override(allow_incompatible: true)
          # @overridable
          #: -> void
          def foo; end
        RB

        assert_equal(<<~RB, Sigs.rbs_to_rbi(contents))
          # @final
          # @override(allow_incompatible: true)
          # @overridable
          sig(:final) { override(allow_incompatible: true).overridable.void }
          def foo; end
        RB
      end

      def test_translate_to_rbi_method_sigs_without_runtime
        contents = <<~RB
          # @without_runtime
          #: -> void
          def foo; end
        RB

        assert_equal(<<~RB, Sigs.rbs_to_rbi(contents))
          # @without_runtime
          T::Sig::WithoutRuntime.sig { void }
          def foo; end
        RB
      end

      def test_translate_to_rbi_singleton_method_sigs
        contents = <<~RB
          class A
            #: -> Integer
            def self.foo
              42
            end
          end
        RB

        assert_equal(<<~RB, Sigs.rbs_to_rbi(contents))
          class A
            sig { returns(Integer) }
            def self.foo
              42
            end
          end
        RB
      end

      def test_translate_to_rbi_attr_sigs
        contents = <<~RB
          class A
            #: Integer
            attr_accessor :a, :b

            #: Integer
            attr_reader :c, :d

            #: Integer
            attr_writer :e
          end
        RB

        assert_equal(<<~RB, Sigs.rbs_to_rbi(contents))
          class A
            sig { returns(Integer) }
            attr_accessor :a, :b

            sig { returns(Integer) }
            attr_reader :c, :d

            sig { params(e: Integer).returns(Integer) }
            attr_writer :e
          end
        RB
      end

      def test_translate_to_rbi_attr_sigs_raises_on_writer_with_multiple_names
        contents = <<~RB
          #: Integer
          attr_writer :a, b
        RB

        assert_raises(Sigs::Error) do
          Sigs.rbs_to_rbi(contents)
        end
      end

      def test_translate_to_rbi_attr_sigs_with_annotations
        contents = <<~RB
          # @final
          # @override(allow_incompatible: true)
          # @overridable
          #: Integer
          attr_accessor :foo
        RB

        assert_equal(<<~RB, Sigs.rbs_to_rbi(contents))
          # @final
          # @override(allow_incompatible: true)
          # @overridable
          sig(:final) { override(allow_incompatible: true).overridable.returns(Integer) }
          attr_accessor :foo
        RB
      end

      def test_translate_to_rbi_attr_sigs_without_runtime
        contents = <<~RB
          # @without_runtime
          #: Integer
          attr_accessor :foo
        RB

        assert_equal(<<~RB, Sigs.rbs_to_rbi(contents))
          # @without_runtime
          T::Sig::WithoutRuntime.sig { returns(Integer) }
          attr_accessor :foo
        RB
      end

      def test_translate_to_rbi_skips_sigs_with_errors
        contents = <<~RB
          class A
            #: foo
            def foo; end
          end
        RB

        assert_equal(contents, Sigs.rbs_to_rbi(contents))
      end

      def test_translate_to_rbi_ignores_yard_comments
        contents = <<~RB
          class A
            #:nodoc:
            def foo; end

            #:yields:
            def bar; end
          end
        RB

        assert_equal(contents, Sigs.rbs_to_rbi(contents))
      end
    end
  end
end
