# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    module Translate
      class RBSCommentsToSorbetSigsTest < Minitest::Test
        def test_translate_to_rbi_empty
          contents = ""
          assert_equal(contents, rbs_comments_to_sorbet_sigs(contents))
        end

        def test_translate_to_rbi_no_sigs
          contents = <<~RB
            class A
              def foo; end
            end
          RB

          assert_equal(contents, rbs_comments_to_sorbet_sigs(contents))
        end

        def test_translate_to_rbi_top_level_sig
          contents = <<~RB
            # typed: true

            #: (Integer a, Integer b) -> Integer
            def foo(a, b)
              a + b
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
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

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
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

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
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

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
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

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
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

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
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

          assert_raises(Translate::Error) do
            rbs_comments_to_sorbet_sigs(contents)
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

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
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

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
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

          assert_equal(contents, rbs_comments_to_sorbet_sigs(contents))
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

          assert_equal(contents, rbs_comments_to_sorbet_sigs(contents))
        end

        private

        #: (String) -> String
        def rbs_comments_to_sorbet_sigs(ruby_contents)
          Translate.rbs_comments_to_sorbet_sigs(ruby_contents, file: "test.rb")
        end
      end
    end
  end
end
