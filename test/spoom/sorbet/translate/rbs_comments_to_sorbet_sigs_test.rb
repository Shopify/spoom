# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    module Translate
      class RBSCommentsToSorbetSigsTest < Minitest::Test
        def test_translate_to_rbi_empty
          contents = ""
          assert_rewrites_rbs(
            from: contents,
            to_pretty_format_for_humans: contents,
          )
        end

        def test_translate_to_rbi_no_sigs
          contents = <<~RB
            class A
              def foo; end
            end
          RB

          assert_rewrites_rbs(
            from: contents,
            to_pretty_format_for_humans: contents,
          )
        end

        def test_translate_to_rbi_top_level_sig
          assert_rewrites_rbs(
            from: <<~RUBY,
              # typed: true

              #: (Integer a, Integer b) -> Integer
              def foo(a, b)
                a + b
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              # typed: true

              sig { params(a: Integer, b: Integer).returns(Integer) }
              def foo(a, b)
                a + b
              end
            RUBY
          )
        end

        def test_translate_to_rbi_method_sigs
          assert_rewrites_rbs(
            from: <<~RUBY,
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
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
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
            RUBY
          )
        end

        def test_translate_to_rbi_method_sigs_with_annotations
          assert_rewrites_rbs(
            from: <<~RUBY,
              # @final
              # @overridable
              #: -> void
              def foo; end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              # @final
              # @overridable
              sig(:final) { overridable.void }
              def foo; end
            RUBY
          )
        end

        def test_translate_to_rbi_method_sigs_with_override_annotations
          assert_rewrites_rbs(
            from: <<~RUBY,
              # @override(allow_incompatible: true)
              #: -> void
              def foo; end

              # @override(allow_incompatible: :visibility)
              #: -> void
              def bar; end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              # @override(allow_incompatible: true)
              sig { override(allow_incompatible: true).void }
              def foo; end

              # @override(allow_incompatible: :visibility)
              sig { override(allow_incompatible: :visibility).void }
              def bar; end
            RUBY
          )
        end

        def test_translate_to_rbi_method_sigs_without_runtime
          assert_rewrites_rbs(
            from: <<~RUBY,
              # @without_runtime
              #: -> void
              def foo; end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              # @without_runtime
              T::Sig::WithoutRuntime.sig { void }
              def foo; end
            RUBY
          )
        end

        def test_translate_to_rbi_method_added_is_always_without_runtime
          assert_rewrites_rbs(
            from: <<~RUBY,
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
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              class A
                class << self
                  # @override
                  T::Sig::WithoutRuntime.sig { override.params(m: Symbol).void }
                  def method_added(m); end

                  # @override
                  T::Sig::WithoutRuntime.sig { override.params(m: Symbol).void }
                  def singleton_method_added(m); end
                end
              end
            RUBY
          )
        end

        def test_translate_to_rbi_singleton_method_sigs
          assert_rewrites_rbs(
            from: <<~RUBY,
              class A
                #: -> Integer
                def self.foo
                  42
                end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              class A
                sig { returns(Integer) }
                def self.foo
                  42
                end
              end
            RUBY
          )
        end

        def test_translate_to_rbi_attr_sigs
          assert_rewrites_rbs(
            from: <<~RUBY,
              class A
                #: Integer
                attr_accessor :a, :b

                #: Integer
                attr_reader :c, :d

                #: Integer
                attr_writer :e
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              class A
                sig { returns(Integer) }
                attr_accessor :a, :b

                sig { returns(Integer) }
                attr_reader :c, :d

                sig { params(e: Integer).returns(Integer) }
                attr_writer :e
              end
            RUBY
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
            from: <<~RUBY,
              # @final
              # @override(allow_incompatible: true)
              # @overridable
              #: Integer
              attr_accessor :foo
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              # @final
              # @override(allow_incompatible: true)
              # @overridable
              sig(:final) { override(allow_incompatible: true).overridable.returns(Integer) }
              attr_accessor :foo
            RUBY
          )
        end

        def test_translate_to_rbi_attr_sigs_without_runtime
          assert_rewrites_rbs(
            from: <<~RUBY,
              # @without_runtime
              #: Integer
              attr_accessor :foo
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              # @without_runtime
              T::Sig::WithoutRuntime.sig { returns(Integer) }
              attr_accessor :foo
            RUBY
          )
        end

        def test_translate_to_rbi_skips_sigs_with_errors
          contents = <<~RB
            class A
              #: foo
              def foo; end
            end
          RB

          assert_rewrites_rbs(
            from: contents,
            to_pretty_format_for_humans: contents,
          )
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

          assert_rewrites_rbs(
            from: contents,
            to_pretty_format_for_humans: contents,
          )
        end

        def test_translate_to_rbi_multiline_sigs
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: Array[
              #|   Integer
              #| ]
              attr_accessor :foo

              #: (
              #|   Integer,
              #|   Integer
              #| ) -> Integer
              def foo(a, b); end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              sig { returns(::T::Array[Integer]) }
              attr_accessor :foo

              sig { params(a: Integer, b: Integer).returns(Integer) }
              def foo(a, b); end
            RUBY
          )
        end

        def test_translate_to_rbi_helpers
          assert_rewrites_rbs(
            from: <<~RUBY,
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
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
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
            RUBY
          )
        end

        def test_translate_to_rbi_does_not_insert_t_helpers_for_random_annotations
          contents = <<~RB
            # @private
            class Foo
            end
          RB

          assert_rewrites_rbs(
            from: contents,
            to_pretty_format_for_humans: contents,
          )
        end

        def test_translate_to_rbi_helpers_with_right_order
          assert_rewrites_rbs(
            from: <<~RUBY,
              # @foo
              # @bar
              # @requires_ancestor: Kernel
              module Baz
                #: -> void
                def foo; end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              # @foo
              # @bar
              module Baz
                extend T::Helpers

                requires_ancestor { Kernel }

                sig { void }
                def foo; end
              end
            RUBY
          )
        end

        def test_translate_to_rbi_generics
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: [in A, out B]
              class A
                #: [A, B < C]
                module B
                  #: [A = singleton(Numeric)]
                  class << self
                  end
                end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
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
            RUBY
          )
        end

        def test_translate_to_rbi_in_block
          assert_rewrites_rbs(
            from: <<~RUBY,
              Class.new do
                #: -> Integer
                def foo
                  42
                end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              Class.new do
                sig { returns(Integer) }
                def foo
                  42
                end
              end
            RUBY
          )
        end

        def test_translate_to_rbi_max_line_length
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: (
              #|   param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
              #|   param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
              #| ) -> void
              def foo(param1:, param2:); end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              sig do
                params(
                  param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
                  param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
                ).void
              end
              def foo(param1:, param2:); end
            RUBY
            max_line_length: 120,
          )
        end

        def test_translate_to_rbi_defs_within_send
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: -> void
              public def foo; end

              #: -> void
              private def bar; end

              #: -> void
              memoize def baz; end

              #: -> void
              abstract def qux; end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              sig { void }
              public def foo; end

              sig { void }
              private def bar; end

              sig { void }
              memoize def baz; end

              sig { void }
              abstract def qux; end
            RUBY
          )
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

          assert_rewrites_rbs(
            from: contents,
            to_pretty_format_for_humans: contents,
          )
        end

        def test_translate_type_alias
          assert_rewrites_rbs(
            from: <<~RUBY,
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
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              module Aliases
                Foo = T.type_alias { ::T.any(Integer, String) }
                MultiLine = T.type_alias { ::T.any(Integer, String) }
              end

              sig { params(a: Aliases::Foo).returns(Aliases::MultiLine) }
              def bar(a)
                42
              end
            RUBY
          )
        end

        def test_translate_type_alias_with_complex_type
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: type Foo::user_id = Integer
              #: type ::Bar::user_data = { id: Foo::user_id, name: String }

              #: (::Bar::user_data data) -> Foo::user_id
              def process_user(data)
                data[:id]
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              Foo::UserId = T.type_alias { Integer }
              ::Bar::UserData = T.type_alias { { id: Foo::UserId, name: String } }

              sig { params(data: ::Bar::UserData).returns(Foo::UserId) }
              def process_user(data)
                data[:id]
              end
            RUBY
          )
        end

        def test_translate_type_alias_in_class
          assert_rewrites_rbs(
            from: <<~RUBY,
              class Example
                #: type status = :pending | :completed | :failed

                #: () -> status
                def get_status
                  :pending
                end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              class Example
                Status = T.type_alias { Symbol }

                sig { returns(Status) }
                def get_status
                  :pending
                end
              end
            RUBY
          )
        end

        def test_translate_type_alias_with_generics
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: type list = Array[Integer]

              #: (list items) -> list
              def double_items(items)
                items.map { |x| x * 2 }
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              List = T.type_alias { ::T::Array[Integer] }

              sig { params(items: List).returns(List) }
              def double_items(items)
                items.map { |x| x * 2 }
              end
            RUBY
          )
        end

        def test_translate_type_alias_with_union
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: type nullable_string = String?

              #: (nullable_string text) -> String
              def ensure_string(text)
                text || ""
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              NullableString = T.type_alias { ::T.nilable(String) }

              sig { params(text: NullableString).returns(String) }
              def ensure_string(text)
                text || ""
              end
            RUBY
          )
        end

        def test_translate_type_alias_that_does_not_exist
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: () -> notFound
              def foo
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              sig { returns(NotFound) }
              def foo
              end
            RUBY
          )
        end

        def test_translate_broken_type_alias_continuation
          assert_rewrites_rbs(
            from: <<~RUBY,
              #: type multiLine =
              #| String
              #| | Integer
              # foo bar baz
              #| | Symbol

              #: () -> multiLine
              def foo
                ""
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              MultiLine = T.type_alias { ::T.any(String, Integer) }
              # foo bar baz
              #| | Symbol

              sig { returns(MultiLine) }
              def foo
                ""
              end
            RUBY
          )
        end

        def test_translate_non_rbs_comment_as_leading_comment_on_class
          contents = <<~RB
            #: not a valid rbs comment
            class Foo
            end
          RB

          assert_rewrites_rbs(
            from: contents,
            to_pretty_format_for_humans: contents,
          )
        end

        def test_translate_type_alias_as_leading_comment_on_class
          assert_rewrites_rbs(
            from: <<~RUBY,
              module Foo
                #: type serialized_range = [Integer, Integer]
                class Range
                end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              module Foo
                SerializedRange = T.type_alias { [Integer, Integer] }
                class Range
                end
              end
            RUBY
          )
        end

        def test_translate_overloads_translate_all_is_default
          assert_rewrites_rbs(
            from: <<~RUBY,
              class Foo
                #: () { (Integer) -> void } -> void
                #: () -> Enumerator[Integer, void]
                def each(&block); end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              class Foo
                sig { params(block: ::T.proc.params(arg0: Integer).void).void }
                sig { returns(::T::Enumerator[Integer, void]) }
                def each(&block); end
              end
            RUBY
          )
        end

        def test_translate_overloads_translate_last
          assert_rewrites_rbs(
            from: <<~RUBY,
              class Foo
                #: () { (Integer) -> void } -> void
                #: () -> Enumerator[Integer, void]
                def each(&block); end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              class Foo
                sig { returns(::T::Enumerator[Integer, void]) }
                def each(&block); end
              end
            RUBY
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
            from: <<~RUBY,
              class Foo
                #: () -> void
                def foo; end
              end
            RUBY

            to_pretty_format_for_humans: <<~RUBY,
              class Foo
                sig { void }
                def foo; end
              end
            RUBY
            overloads_strategy: :translate_last,
          )
        end

        def test_contains_rbs_syntax_returns_true_for_supported_rbs_annotations
          [
            "# @abstract",
            "# @interface",
            "# @sealed",
            "# @final",
            "# @requires_ancestor:",
            "# @override",
            "# @override(allow_incompatible: true)",
            "# @override(allow_incompatible: false)",
            "# @override(allow_incompatible: :visibility)",
            "# @overridable",
            "# @without_runtime",
          ].each do |marker|
            assert(
              RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB),
                # typed: true

                #{marker}
                class Foo; end
              RB
              "#contains_rbs_syntax? should return true for files containing #{marker}",
            )
          end
        end

        def test_contains_rbs_syntax_returns_true_for_supported_typed_sigils
          [
            "# typed: ignore",
            "# typed: false",
            "# typed: true",
            "# typed: strict",
            "# typed: strong",
            "# typed: __STDLIB_INTERNAL",
          ].each do |sigil|
            assert(
              RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB),
                #{sigil}

                #: -> void
                def foo; end
              RB
              "#contains_rbs_syntax? should return true for files containing #{sigil}",
            )
          end
        end

        def test_contains_rbs_syntax_returns_true_when_typed_sigil_is_after_other_magic_comments
          assert(RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB))
            # frozen_string_literal: true
            # typed: true

            class Foo
              #: -> String
              def foo; end
            end
          RB

          assert(RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB))
            # frozen_string_literal: true

            # typed: true

            class Foo
              #: -> String
              def foo; end
            end
          RB
        end

        def test_contains_rbs_syntax_returns_true_for_rbs_comments
          assert(RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB))
            # typed: true

            class Foo
              #: -> String
              def foo; end
            end
          RB
        end

        def test_contains_rbs_syntax_returns_true_for_multiline_rbs_comments
          assert(RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB))
            # typed: true

            class Foo
              #: -> Array[
              #| String
              #| ]
              def foo; end
            end
          RB
        end

        def test_contains_rbs_syntax_returns_false_for_files_without_typed_sigil
          refute(RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB))
            #: -> void
            def foo; end
          RB
        end

        def test_contains_rbs_syntax_returns_false_for_files_without_rbs_syntax
          refute(RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB))
            # typed: true

            class Foo
              def foo; end
            end
          RB
        end

        def test_contains_rbs_syntax_returns_false_for_unrelated_yard_tags
          refute(RBSCommentsToSorbetSigs.contains_rbs_syntax?(<<~RB))
            # typed: true

            # @param value [String]
            # @return [String]
            def foo(value); end
          RB
        end

        def test_rewrite_does_not_call_new_for_files_without_rbs_syntax
          source = <<~RB
            # typed: true

            class Foo
              def foo; end
            end
          RB

          RBSCommentsToSorbetSigs.stub(:new, ->(*) { flunk("should not be called") }) do
            assert_equal(source, RBSCommentsToSorbetSigs.rewrite_if_needed(source, file: "test.rb"))
          end
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

        #: (
        #|   from: String,
        #|   to_pretty_format_for_humans: String,
        #|   ?max_line_length: Integer?,
        #|   ?overloads_strategy: Symbol
        #|  ) -> void
        def assert_rewrites_rbs(
          from:,
          to_pretty_format_for_humans:,
          max_line_length: nil,
          overloads_strategy: :translate_all
        )
          source_with_rbs = from
          expected_pretty_format = to_pretty_format_for_humans

          begin # Validate the human-readable rewrite
            rewritten_output = rbs_comments_to_sorbet_sigs(
              source_with_rbs,
              max_line_length:,
              overloads_strategy:,
            )

            assert_equal(expected_pretty_format, rewritten_output)
          end
        end
      end
    end
  end
end
