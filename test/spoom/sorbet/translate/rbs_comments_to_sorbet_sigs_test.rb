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
            # @overridable
            #: -> void
            def foo; end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            # @final
            # @overridable
            sig(:final) { overridable.void }
            def foo; end
          RB
        end

        def test_translate_to_rbi_method_sigs_with_override_annotations
          contents = <<~RB
            # @override(allow_incompatible: true)
            #: -> void
            def foo; end

            # @override(allow_incompatible: :visibility)
            #: -> void
            def bar; end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            # @override(allow_incompatible: true)
            sig { override(allow_incompatible: true).void }
            def foo; end

            # @override(allow_incompatible: :visibility)
            sig { override(allow_incompatible: :visibility).void }
            def bar; end
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

        def test_translate_to_rbi_multiline_sigs
          contents = <<~RB
            #: Array[
            #|   Integer
            #| ]
            attr_accessor :foo

            #: (
            #|   Integer,
            #|   Integer
            #| ) -> Integer
            def foo(a, b); end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            sig { returns(::T::Array[Integer]) }
            attr_accessor :foo

            sig { params(a: Integer, b: Integer).returns(Integer) }
            def foo(a, b); end
          RB
        end

        def test_translate_to_rbi_helpers
          contents = <<~RB
            # @abstract
            # @requires_ancestor: singleton(Foo::Bar)
            class A
              # @interface
              # @sealed
              module B
                # @final
                class << self
                end
              end
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            class A
              extend T::Helpers

              abstract!

              requires_ancestor { ::T.class_of(Foo::Bar) }

              module B
                extend T::Helpers

                interface!

                sealed!

                class << self
                  extend T::Helpers

                  final!
                end
              end
            end
          RB
        end

        def test_translate_to_rbi_does_not_insert_t_helpers_for_random_annotations
          contents = <<~RB
            # @private
            class Foo
            end
          RB

          assert_equal(contents, rbs_comments_to_sorbet_sigs(contents))
        end

        def test_translate_to_rbi_helpers_with_right_order
          contents = <<~RB
            # @foo
            # @bar
            # @requires_ancestor: Kernel
            module Baz
              #: -> void
              def foo; end
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            # @foo
            # @bar
            module Baz
              extend T::Helpers

              requires_ancestor { Kernel }

              sig { void }
              def foo; end
            end
          RB
        end

        def test_translate_to_rbi_generics
          contents = <<~RB
            #: [in A, out B]
            class A
              #: [A, B < C]
              module B
                #: [A = singleton(Numeric)]
                class << self
                end
              end
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            class A
              extend T::Generic

              A = type_member(:in)

              B = type_member(:out)

              module B
                extend T::Generic

                A = type_member

                B = type_member {{ upper: C }}

                class << self
                  extend T::Generic

                  A = type_member {{ fixed: ::T.class_of(Numeric) }}
                end
              end
            end
          RB
        end

        def test_translate_to_rbi_in_block
          contents = <<~RB
            Class.new do
              #: -> Integer
              def foo
                42
              end
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            Class.new do
              sig { returns(Integer) }
              def foo
                42
              end
            end
          RB
        end

        def test_translate_to_rbi_max_line_length
          contents = <<~RB
            #: (
            #|   param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
            #|   param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
            #| ) -> void
            def foo(param1:, param2:); end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents, max_line_length: 120))
            sig do
              params(
                param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
                param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
              ).void
            end
            def foo(param1:, param2:); end
          RB
        end

        def test_translate_to_rbi_defs_within_send
          contents = <<~RB
            #: -> void
            public def foo; end

            #: -> void
            private def bar; end

            #: -> void
            memoize def baz; end

            #: -> void
            abstract def qux; end
          RB

          assert_equal(<<~RBS, rbs_comments_to_sorbet_sigs(contents))
            sig { void }
            public def foo; end

            sig { void }
            private def bar; end

            sig { void }
            memoize def baz; end

            sig { void }
            abstract def qux; end
          RBS
        end

        def test_translate_to_rbi_selects_right_comments
          contents = <<~RB
            #: -> void

            class Foo
              #: -> void

              #: -> void

              class << self
                #: -> void

                def bar; end
              end
            end
          RB

          assert_equal(contents, rbs_comments_to_sorbet_sigs(contents))
        end

        def test_translate_type_alias
          contents = <<~RB
            module Aliases
              #: type foo = Integer | String
              #: type multiLine =
              #|   Integer |
              #|   String
            end

            #: (Aliases::foo a) -> Aliases::multiLine
            def bar(a)
              42
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            module Aliases
              Foo = T.type_alias { ::T.any(Integer, String) }
              MultiLine = T.type_alias { ::T.any(Integer, String) }
            end

            sig { params(a: Aliases::Foo).returns(Aliases::MultiLine) }
            def bar(a)
              42
            end
          RB
        end

        def test_translate_type_alias_with_complex_type
          contents = <<~RB
            #: type Foo::user_id = Integer
            #: type ::Bar::user_data = { id: Foo::user_id, name: String }

            #: (::Bar::user_data data) -> Foo::user_id
            def process_user(data)
              data[:id]
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            Foo::UserId = T.type_alias { Integer }
            ::Bar::UserData = T.type_alias { { id: Foo::UserId, name: String } }

            sig { params(data: ::Bar::UserData).returns(Foo::UserId) }
            def process_user(data)
              data[:id]
            end
          RB
        end

        def test_translate_type_alias_in_class
          contents = <<~RB
            class Example
              #: type status = :pending | :completed | :failed

              #: () -> status
              def get_status
                :pending
              end
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            class Example
              Status = T.type_alias { ::T.untyped }

              sig { returns(Status) }
              def get_status
                :pending
              end
            end
          RB
        end

        def test_translate_type_alias_with_generics
          contents = <<~RB
            #: type list = Array[Integer]

            #: (list items) -> list
            def double_items(items)
              items.map { |x| x * 2 }
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            List = T.type_alias { ::T::Array[Integer] }

            sig { params(items: List).returns(List) }
            def double_items(items)
              items.map { |x| x * 2 }
            end
          RB
        end

        def test_translate_type_alias_with_union
          contents = <<~RB
            #: type nullable_string = String?

            #: (nullable_string text) -> String
            def ensure_string(text)
              text || ""
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            NullableString = T.type_alias { ::T.nilable(String) }

            sig { params(text: NullableString).returns(String) }
            def ensure_string(text)
              text || ""
            end
          RB
        end

        def test_translate_type_alias_that_does_not_exist
          contents = <<~RB
            #: () -> notFound
            def foo
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            sig { returns(NotFound) }
            def foo
            end
          RB
        end

        def test_translate_broken_type_alias_continuation
          contents = <<~RB
            #: type multiLine =
            #| String
            #| | Integer
            # foo bar baz
            #| | Symbol

            #: () -> multiLine
            def foo
              ""
            end
          RB

          assert_equal(<<~RB, rbs_comments_to_sorbet_sigs(contents))
            MultiLine = T.type_alias { ::T.any(String, Integer) }
            # foo bar baz
            #| | Symbol

            sig { returns(MultiLine) }
            def foo
              ""
            end
          RB
        end

        private

        #: (String, ?max_line_length: Integer?) -> String
        def rbs_comments_to_sorbet_sigs(ruby_contents, max_line_length: nil)
          Translate.rbs_comments_to_sorbet_sigs(ruby_contents, file: "test.rb", max_line_length: max_line_length)
        end
      end
    end
  end
end
