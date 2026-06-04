# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    module Translate
      class RBSCommentsToLineMatchedSorbetSigsTest < Minitest::Test
        def test_translate_to_rbi_empty
          assert_rewrites_rbs_no_op("")
        end

        def test_translate_to_rbi_no_sigs
          assert_rewrites_rbs_no_op(<<~RBS)
            class A
              def foo; end
            end
          RBS
        end

        def test_translate_to_rbi_top_level_sig
          assert_rewrites_rbs(
            from: <<~RBS,
              # typed: true

              #: (Integer a, Integer b) -> Integer
              def foo(a, b)
                a + b
              end
            RBS
            to: <<~RBI,
              # typed: true

              sig { params(a: Integer, b: Integer).returns(Integer) }
              def foo(a, b)
                a + b
              end
            RBI
          )
        end

        def test_translate_to_rbi_method_sigs
          assert_rewrites_rbs(
            from: <<~RBS,
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
            to: <<~RBI,
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
          )
        end

        def test_translate_to_rbi_method_sigs_with_annotations
          assert_rewrites_rbs(
            from: <<~RBS,
              # @final
              # @overridable
              #: -> void
              def foo; end
            RBS
            to: <<~RBI,
              # @final
              # @overridable
              sig(:final) { overridable.void }
              def foo; end
            RBI
          )
        end

        def test_translate_to_rbi_method_sigs_with_override_annotations
          assert_rewrites_rbs(
            from: <<~RBS,
              # @override(allow_incompatible: true)
              #: -> void
              def foo; end

              # @override(allow_incompatible: :visibility)
              #: -> void
              def bar; end
            RBS
            to: <<~RBI,
              # @override(allow_incompatible: true)
              sig { override(allow_incompatible: true).void }
              def foo; end

              # @override(allow_incompatible: :visibility)
              sig { override(allow_incompatible: :visibility).void }
              def bar; end
            RBI
          )
        end

        def test_translate_to_rbi_method_sigs_without_runtime
          assert_rewrites_rbs(
            from: <<~RBS,
              # @without_runtime
              #: -> void
              def foo; end
            RBS
            to: <<~RBI,
              # @without_runtime
              ::T::Sig::WithoutRuntime.sig { void }
              def foo; end
            RBI
          )
        end

        def test_translate_to_rbi_method_added_is_always_without_runtime
          assert_rewrites_rbs(
            from: <<~RBS,
              class A
                class << self
                  # @override
                  #: (Symbol) -> void
                  def method_added(m); end

                  # @override
                  #: (Symbol) -> void
                  def singleton_method_added(m); end
                end
              end
            RBS
            to: <<~RBI,
              class A
                class << self
                  # @override
                  ::T::Sig::WithoutRuntime.sig { override.params(m: Symbol).void }
                  def method_added(m); end

                  # @override
                  ::T::Sig::WithoutRuntime.sig { override.params(m: Symbol).void }
                  def singleton_method_added(m); end
                end
              end
            RBI
          )
        end

        def test_translate_to_rbi_singleton_method_sigs
          assert_rewrites_rbs(
            from: <<~RBS,
              class A
                #: -> Integer
                def self.foo
                  42
                end
              end
            RBS
            to: <<~RBI,
              class A
                sig { returns(Integer) }
                def self.foo
                  42
                end
              end
            RBI
          )
        end

        def test_translate_to_rbi_attr_sigs
          assert_rewrites_rbs(
            from: <<~RBS,
              class A
                #: Integer
                attr_accessor :a, :b

                #: Integer
                attr_reader :c, :d

                #: Integer
                attr_writer :e
              end
            RBS
            to: <<~RBI,
              class A
                sig { returns(Integer) }
                attr_accessor :a, :b

                sig { returns(Integer) }
                attr_reader :c, :d

                sig { params(e: Integer).returns(Integer) }
                attr_writer :e
              end
            RBI
          )
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
          assert_rewrites_rbs(
            from: <<~RBS,
              # @final
              # @override(allow_incompatible: true)
              # @overridable
              #: Integer
              attr_accessor :foo
            RBS
            to: <<~RBI,
              # @final
              # @override(allow_incompatible: true)
              # @overridable
              sig(:final) { override(allow_incompatible: true).overridable.returns(Integer) }
              attr_accessor :foo
            RBI
          )
        end

        def test_translate_to_rbi_attr_sigs_without_runtime
          assert_rewrites_rbs(
            from: <<~RBS,
              # @without_runtime
              #: Integer
              attr_accessor :foo
            RBS
            to: <<~RBI,
              # @without_runtime
              ::T::Sig::WithoutRuntime.sig { returns(Integer) }
              attr_accessor :foo
            RBI
          )
        end

        def test_translate_to_rbi_skips_sigs_with_errors
          assert_rewrites_rbs_no_op(<<~RBS)
            class A
              #: foo
              def foo; end
            end
          RBS
        end

        def test_translate_to_rbi_ignores_yard_comments
          assert_rewrites_rbs_no_op(<<~RBS)
            class A
              #:nodoc:
              def foo; end

              #:yields:
              def bar; end
            end
          RBS
        end

        def test_translate_to_rbi_multiline_sigs
          assert_rewrites_rbs(
            from: <<~RBS,
              #: Array[
              #|   Integer
              #| ]
              attr_accessor :foo

              #: (
              #|   Integer,
              #|   Integer
              #| ) -> Integer
              def foo(a, b); end
            RBS
            to: <<~RBI,
              sig do returns(::T::Array[
                Integer
              ]) end
              attr_accessor :foo

              sig do params(
                a: Integer,
                b: Integer
              ).returns(Integer) end
              def foo(a, b); end
            RBI
          )
        end

        def test_translate_to_rbi_helpers
          assert_rewrites_rbs(
            from: <<~RBS,
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
            RBS
            to: <<~RBI,
              # RBS_REWRITTEN_ANNOTATION: @abstract
              # RBS_REWRITTEN_ANNOTATION: @requires_ancestor: singleton(Foo::Bar)
              class A; extend T::Helpers; abstract!; requires_ancestor { ::T.class_of(Foo::Bar) }
                # RBS_REWRITTEN_ANNOTATION: @interface
                # RBS_REWRITTEN_ANNOTATION: @sealed
                module B; extend T::Helpers; interface!; sealed!
                  # RBS_REWRITTEN_ANNOTATION: @final
                  class << self; extend T::Helpers; final!
                  end
                end
              end
            RBI
          )
        end

        def test_translate_to_rbi_does_not_insert_t_helpers_for_random_annotations
          assert_rewrites_rbs_no_op(<<~RBS)
            # @private
            class Foo
            end
          RBS
        end

        def test_translate_to_rbi_helpers_with_right_order
          assert_rewrites_rbs(
            from: <<~RBS,
              # @foo
              # @bar
              # @requires_ancestor: Kernel
              module Baz
                #: -> void
                def foo; end
              end
            RBS
            to: <<~RBI,
              # RBS_IGNORED_UNKNOWN_ANNOTATION: @foo
              # RBS_IGNORED_UNKNOWN_ANNOTATION: @bar
              # RBS_REWRITTEN_ANNOTATION: @requires_ancestor: Kernel
              module Baz; extend T::Helpers; requires_ancestor { Kernel }
                sig { void }
                def foo; end
              end
            RBI
          )
        end

        def test_translate_to_rbi_generics
          assert_rewrites_rbs(
            from: <<~RBS,
              #: [in A, out B]
              class A
                #: [A, B < C]
                module B
                  #: [A = singleton(Numeric)]
                  class << self
                  end
                end
              end
            RBS
            to: <<~RBI,
              class A; extend T::Generic; A = type_member(:in); B = type_member(:out)
                module B; extend T::Generic; A = type_member; B = type_member {{ upper: C }}
                  class << self
                    extend T::Generic

                    A = type_member {{ fixed: ::T.class_of(Numeric) }}
                  end
                end
              end
            RBI
          )
        end

        def test_translate_to_rbi_in_block
          assert_rewrites_rbs(
            from: <<~RBS,
              Class.new do
                #: -> Integer
                def foo
                  42
                end
              end
            RBS
            to: <<~RBI,
              Class.new do
                sig { returns(Integer) }
                def foo
                  42
                end
              end
            RBI
          )
        end

        def test_translate_to_rbi_max_line_length
          assert_rewrites_rbs(
            from: <<~RBS,
              #: (
              #|   param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
              #|   param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
              #| ) -> void
              def foo(param1:, param2:); end
            RBS
            to: <<~RBI,
              sig do params(
                param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
                param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
              ).void end
              def foo(param1:, param2:); end
            RBI
            max_line_length: 120,
          )
        end

        def test_translate_to_rbi_defs_within_send
          assert_rewrites_rbs(
            from: <<~RBS,
              #: -> void
              public def foo; end

              #: -> void
              private def bar; end

              #: -> void
              memoize def baz; end

              #: -> void
              abstract def qux; end
            RBS
            to: <<~RBI,
              sig { void }
              public def foo; end

              sig { void }
              private def bar; end

              sig { void }
              memoize def baz; end

              sig { void }
              abstract def qux; end
            RBI
          )
        end

        def test_translate_to_rbi_selects_right_comments
          assert_rewrites_rbs_no_op(<<~RBS)
            #: -> void

            class Foo
              #: -> void

              #: -> void

              class << self
                #: -> void

                def bar; end
              end
            end
          RBS
        end

        def test_translate_type_alias
          assert_rewrites_rbs(
            from: <<~RBS,
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
            RBS
            to: <<~RBI,
              module Aliases
                Foo = T.type_alias { ::T.any(Integer, String) }
                MultiLine = T.type_alias do ::T.any(
                  Integer,
                  String) end
              end

              sig { params(a: Aliases::Foo).returns(Aliases::MultiLine) }
              def bar(a)
                42
              end
            RBI
          )
        end

        def test_translate_type_alias_with_complex_type
          assert_rewrites_rbs(
            from: <<~RBS,
              #: type Foo::user_id = Integer
              #: type ::Bar::user_data = { id: Foo::user_id, name: String }

              #: (::Bar::user_data data) -> Foo::user_id
              def process_user(data)
                data[:id]
              end
            RBS
            to: <<~RBI,
              Foo::UserId = T.type_alias { Integer }
              ::Bar::UserData = T.type_alias { { id: Foo::UserId, name: String } }

              sig { params(data: ::Bar::UserData).returns(Foo::UserId) }
              def process_user(data)
                data[:id]
              end
            RBI
          )
        end

        def test_translate_type_alias_in_class
          assert_rewrites_rbs(
            from: <<~RBS,
              class Example
                #: type status = :pending | :completed | :failed

                #: () -> status
                def get_status
                  :pending
                end
              end
            RBS
            to: <<~RBI,
              class Example
                Status = T.type_alias { Symbol }

                sig { returns(Status) }
                def get_status
                  :pending
                end
              end
            RBI
          )
        end

        def test_translate_type_alias_with_generics
          assert_rewrites_rbs(
            from: <<~RBS,
              #: type list = Array[Integer]

              #: (list items) -> list
              def double_items(items)
                items.map { |x| x * 2 }
              end
            RBS
            to: <<~RBI,
              List = T.type_alias { ::T::Array[Integer] }

              sig { params(items: List).returns(List) }
              def double_items(items)
                items.map { |x| x * 2 }
              end
            RBI
          )
        end

        def test_translate_type_alias_with_union
          assert_rewrites_rbs(
            from: <<~RBS,
              #: type nullable_string = String?

              #: (nullable_string text) -> String
              def ensure_string(text)
                text || ""
              end
            RBS
            to: <<~RBI,
              NullableString = T.type_alias { ::T.nilable(String) }

              sig { params(text: NullableString).returns(String) }
              def ensure_string(text)
                text || ""
              end
            RBI
          )
        end

        def test_translate_type_alias_that_does_not_exist
          assert_rewrites_rbs(
            from: <<~RBS,
              #: () -> notFound
              def foo
              end
            RBS
            to: <<~RBI,
              sig { returns(NotFound) }
              def foo
              end
            RBI
          )
        end

        def test_translate_broken_type_alias_continuation
          assert_rewrites_rbs(
            from: <<~RBS,
              #: type multiLine =
              #| String
              #| | Integer
              # foo bar baz
              #| | Symbol

              #: () -> multiLine
              def foo
                ""
              end
            RBS
            to: <<~RBI,
              MultiLine = T.type_alias do ::T.any(
                String,
                Integer) end
              # foo bar baz
              #| | Symbol

              sig { returns(MultiLine) }
              def foo
                ""
              end
            RBI
          )
        end

        def test_translate_non_rbs_comment_as_leading_comment_on_class
          assert_rewrites_rbs_no_op(<<~RBS)
            #: not a valid rbs comment
            class Foo
            end
          RBS
        end

        def test_translate_type_alias_as_leading_comment_on_class
          assert_rewrites_rbs(
            from: <<~RBS,
              module Foo
                #: type serialized_range = [Integer, Integer]
                class Range
                end
              end
            RBS
            to: <<~RBI,
              module Foo
                SerializedRange = T.type_alias { [Integer, Integer] }
                class Range
                end
              end
            RBI
          )
        end

        def test_translate_overloads_translate_all_is_default
          assert_rewrites_rbs(
            from: <<~RBS,
              class Foo
                #: () { (Integer) -> void } -> void
                #: () -> Enumerator[Integer, void]
                def each(&block); end
              end
            RBS
            to: <<~RBI,
              class Foo
                sig { params(block: ::T.proc.params(arg0: Integer).void).void }
                sig { returns(::T::Enumerator[Integer, void]) }
                def each(&block); end
              end
            RBI
          )
        end

        def test_translate_overloads_translate_last
          assert_rewrites_rbs(
            from: <<~RBS,
              class Foo
                #: () { (Integer) -> void } -> void
                #: () -> Enumerator[Integer, void]
                def each(&block); end
              end
            RBS
            to: <<~RBI,
              class Foo
                # RBS deleted overload: () { (Integer) -> void } -> void
                sig { returns(::T::Enumerator[Integer, void]) }
                def each(&block); end
              end
            RBI
            overloads_strategy: :translate_last,
          )
        end

        def test_translate_overloads_raise
          contents = <<~RB
            class Foo
              #: () { (Integer) -> void } -> void
              #: () -> Enumerator[Integer, void]
              def each(&block); end
            end
          RB

          error = assert_raises(Translate::Error) do
            rbs_comments_to_sorbet_sigs(contents, overloads_strategy: :raise)
          end
          assert_equal("Method `each` at test.rb:4 has multiple overloaded signatures", error.message)
        end

        def test_translate_overloads_single_signature_unaffected
          assert_rewrites_rbs(
            from: <<~RBS,
              class Foo
                #: () -> void
                def foo; end
              end
            RBS
            to: <<~RBI,
              class Foo
                sig { void }
                def foo; end
              end
            RBI
            overloads_strategy: :translate_last,
          )
        end

        private

        #: (String, ?max_line_length: Integer?, ?overloads_strategy: Symbol) -> String
        def rbs_comments_to_sorbet_sigs(ruby_contents, max_line_length: nil, overloads_strategy: :translate_all)
          RBSCommentsToSorbetSigs.new(
            ruby_contents,
            file: "test.rb",
            max_line_length: max_line_length,
            overloads_strategy: overloads_strategy,
          ).rewrite
        end

        #: (from: String, to: String, ?max_line_length: Integer?, ?overloads_strategy: Symbol) -> String
        def assert_rewrites_rbs(from:, to:, max_line_length: nil, overloads_strategy: :translate_all)
          source_with_rbs = from
          expected_output = to

          assert_equal(source_with_rbs.lines.count, expected_output.lines.count, <<~MSG)
            Precondition: the expected rewritten code should have the same line count as the RBS-containing input.
            This is a mistake in the test case, not the rewriter.
          MSG

          rewritten_output = rbs_comments_to_sorbet_sigs(
            source_with_rbs,
            max_line_length:,
            overloads_strategy:,
          )

          # TODO: run the validator to compare the two results
          assert_equal(expected_output, rewritten_output)
        end

        def assert_rewrites_rbs_no_op(content)
          assert_rewrites_rbs(from: content, to: content)
        end
      end
    end
  end
end
