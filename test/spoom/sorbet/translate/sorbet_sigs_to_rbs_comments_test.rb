# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    module Translate
      class SorbetSigsToRBSCommentsTest < Minitest::Test
        def test_translate_to_rbs_empty
          contents = ""
          assert_equal(contents, sorbet_sigs_to_rbs_comments(contents))
        end

        def test_translate_to_rbs_no_sigs
          contents = <<~RB
            class A
              def foo; end
            end
          RB

          assert_equal(contents, sorbet_sigs_to_rbs_comments(contents))
        end

        def test_translate_to_rbs_top_level_sig
          contents = <<~RB
            # typed: true

            sig { params(a: Integer, b: Integer).returns(Integer) }
            def foo(a, b)
              a + b
            end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
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

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
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

        def test_translate_to_rbs_method_with_anonymous_params
          contents = <<~RB
            class A
              sig { params("*": Integer, "**": Integer, "&": ::T.proc.void).returns(Integer) }
              def foo(*, **, &); end
            end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            class A
              #: (*Integer, **Integer) { -> void } -> Integer
              def foo(*, **, &); end
            end
          RBS
        end

        def test_translate_to_rbs_abstract_methods
          contents = <<~RB
            class Foo
              sig { abstract.void }
              def foo; end

              class Bar
                sig { abstract.void }
                def bar; end
              end

              sig { abstract.params(x: Integer).void }
              def baz(x)
              end

              sig { abstract.params(x: Integer).void }
              def foo=(x); end

              sig { abstract.params(x: Integer).void }
              def bar=(x)
              end
            end
          RB

          assert_equal(contents, sorbet_sigs_to_rbs_comments(contents, translate_abstract_methods: false))

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            class Foo
              # @abstract
              #: -> void
              def foo = raise NotImplementedError, "Abstract method called"

              class Bar
                # @abstract
                #: -> void
                def bar = raise NotImplementedError, "Abstract method called"
              end

              # @abstract
              #: (Integer x) -> void
              def baz(x) = raise NotImplementedError, "Abstract method called"

              # @abstract
              #: (Integer x) -> void
              def foo=(x)
                raise NotImplementedError, "Abstract method called"
              end

              # @abstract
              #: (Integer x) -> void
              def bar=(x)
                raise NotImplementedError, "Abstract method called"
              end
            end
          RBS
        end

        def test_translate_method_sigs_to_rbs_without_positional_names
          contents = <<~RBI
            class A
              sig { params(a: Integer, b: Integer, c: Integer, d: Integer, e: Integer, f: Integer).void }
              def initialize(a, b = 42, *c, d:, e: 42, **f); end
            end
          RBI

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents, positional_names: false))
            class A
              #: (Integer, ?Integer, *Integer, d: Integer, ?e: Integer, **Integer f) -> void
              def initialize(a, b = 42, *c, d:, e: 42, **f); end
            end
          RBS
        end

        def test_translate_to_rbs_method_sigs_with_annotations
          contents = <<~RB
            sig(:final) { overridable.void }
            def foo; end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            # @final
            # @overridable
            #: -> void
            def foo; end
          RBS
        end

        def test_translate_to_rbs_method_sigs_with_overridable_annotation_indented
          contents = <<~RB
            class Foo
              sig { overridable.params(x: Integer).returns(String) }
              def foo(x); end
            end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            class Foo
              # @overridable
              #: (Integer x) -> String
              def foo(x); end
            end
          RBS
        end

        def test_translate_to_rbs_method_sigs_with_override_annotations
          contents = <<~RB
            sig { override(allow_incompatible: true).void }
            def foo; end

            sig { override(allow_incompatible: :visibility).void }
            def bar; end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            # @override(allow_incompatible: true)
            #: -> void
            def foo; end

            # @override(allow_incompatible: :visibility)
            #: -> void
            def bar; end
          RBS
        end

        def test_translate_to_rbs_method_sigs_without_runtime
          contents = <<~RB
            ::T::Sig::WithoutRuntime.sig { void }
            def foo; end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
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

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
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

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
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

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            # @final
            # @override(allow_incompatible: true)
            # @overridable
            #: Integer
            attr_accessor :foo
          RBS
        end

        def test_translate_to_rbs_attr_sigs_without_runtime
          contents = <<~RB
            ::T::Sig::WithoutRuntime.sig { returns(Integer) }
            attr_accessor :foo
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            # @without_runtime
            #: Integer
            attr_accessor :foo
          RBS
        end

        def test_translate_to_rbs_helpers
          contents = <<~RB
            class A
              extend T::Helpers
              abstract!
              requires_ancestor { T.class_of(Foo::Bar) }
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

          assert_equal(contents, sorbet_sigs_to_rbs_comments(contents, translate_helpers: false))

          assert_equal(<<~RB, sorbet_sigs_to_rbs_comments(contents))
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
        end

        def test_translate_to_rbs_helpers_do_not_remove_extend_helpers_if_no_helper_was_removed
          contents = <<~RB
            module Foo
              extend T::Helpers

              mixes_in_class_methods Bar

              module Bar
                def bar
                end
              end
            end

            module Baz
              extend T::Helpers

              mixes_in_class_methods Foo::Bar
              requires_ancestor { Foo::Bar }
            end
          RB

          assert_equal(<<~RB, sorbet_sigs_to_rbs_comments(contents))
            module Foo
              extend T::Helpers

              mixes_in_class_methods Bar

              module Bar
                def bar
                end
              end
            end

            # @requires_ancestor: Foo::Bar
            module Baz
              extend T::Helpers

              mixes_in_class_methods Foo::Bar
            end
          RB
        end

        def test_translate_to_rbs_generics
          contents = <<~RB
            class A
              extend T::Generic
              X = type_member(:in)
              Y = type_member(:out)
              module B
                extend T::Generic
                X = type_member
                Y = type_member {{ upper: C }}
                class << self
                  extend T::Generic
                  X = type_member {{ fixed: T.class_of(Numeric) }}
                end
              end
            end
          RB

          assert_equal(contents, sorbet_sigs_to_rbs_comments(contents, translate_generics: false))

          assert_equal(<<~RB, sorbet_sigs_to_rbs_comments(contents))
            #: [in X, out Y]
            class A
              #: [X, Y < C]
              module B
                #: [X = singleton(Numeric)]
                class << self
                end
              end
            end
          RB
        end

        def test_translate_to_rbs_in_block
          contents = <<~RB
            Class.new do
              sig { returns(Integer) }
              def foo
                42
              end
            end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            Class.new do
              #: -> Integer
              def foo
                42
              end
            end
          RBS
        end

        def test_translate_to_rbs_with_nested_nilable_param
          contents = <<~RB
            Class.new do
              sig { params(x: T.nilable(T.nilable(Integer))).void }
              def foo(x); end
            end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            Class.new do
              #: (Integer? x) -> void
              def foo(x); end
            end
          RBS
        end

        def test_translate_to_rbs_with_nested_any_param
          contents = <<~RB
            Class.new do
              sig { params(x: T.any(T.any(Integer, String), Float, Integer)).void }
              def foo(x); end
            end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            Class.new do
              #: ((Integer | String | Float) x) -> void
              def foo(x); end
            end
          RBS
        end

        def test_translate_to_rbs_with_nested_all_param
          contents = <<~RB
            Class.new do
              sig { params(x: T.all(T.all(Enumerable, Comparable), Numeric, Enumerable)).void }
              def foo(x); end
            end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            Class.new do
              #: ((Enumerable & Comparable & Numeric) x) -> void
              def foo(x); end
            end
          RBS
        end

        def test_translate_to_rbs_multline_for_long_sigs
          contents = <<~RB
            sig do
              params(
                param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
                param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
              ).void
            end
            def foo(param1:, param2:); end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents, max_line_length: 120))
            #: (
            #|   param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
            #|   param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
            #| ) -> void
            def foo(param1:, param2:); end
          RBS
        end

        def test_translate_to_rbs_defs_within_send
          contents = <<~RB
            sig { void }
            public def foo; end

            sig { void }
            private def bar; end

            sig { void }
            memoize def baz; end

            sig { void }
            abstract def qux; end
          RB

          assert_equal(<<~RBS, sorbet_sigs_to_rbs_comments(contents))
            #: -> void
            public def foo; end

            #: -> void
            private def bar; end

            #: -> void
            memoize def baz; end

            #: -> void
            abstract def qux; end
          RBS
        end

        def test_translate_to_rbs_keeps_multiline_sigs
          contents = <<~RB
            sig do
              params(
                a: A,
                b: B
              ).void
            end
            def foo(a, b); end

            sig { params(a: A, b: B).void }
            def bar(a, b); end

            sig { params(a: A, b: B, c: C, d: D, e: E, f: F, g: G, h: H, i: I, j: J, k: K, l: L, m: M, n: N, o: O, p: P, q: Q, r: R, s: S, t: T, u: U, v: V, w: W, x: X, y: Y, z: Z).void }
            def baz(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z); end
          RB

          output = sorbet_sigs_to_rbs_comments(contents, max_line_length: 50)
          assert_equal(<<~RBS, output)
            #: (
            #|   A a,
            #|   B b
            #| ) -> void
            def foo(a, b); end

            #: (A a, B b) -> void
            def bar(a, b); end

            #: (
            #|   A a,
            #|   B b,
            #|   C c,
            #|   D d,
            #|   E e,
            #|   F f,
            #|   G g,
            #|   H h,
            #|   I i,
            #|   J j,
            #|   K k,
            #|   L l,
            #|   M m,
            #|   N n,
            #|   O o,
            #|   P p,
            #|   Q q,
            #|   R r,
            #|   S s,
            #|   T t,
            #|   U u,
            #|   V v,
            #|   W w,
            #|   X x,
            #|   Y y,
            #|   Z z
            #| ) -> void
            def baz(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z); end
          RBS
        end

        private

        #: (
        #|   String,
        #|   ?positional_names: bool,
        #|   ?preserve_multiline_signatures: bool,
        #|   ?max_line_length: Integer?,
        #|   ?translate_generics: bool,
        #|   ?translate_helpers: bool,
        #|   ?translate_abstract_methods: bool
        #| ) -> String
        def sorbet_sigs_to_rbs_comments(
          ruby_contents,
          positional_names: true,
          preserve_multiline_signatures: true,
          max_line_length: nil,
          translate_generics: true,
          translate_helpers: true,
          translate_abstract_methods: true
        )
          Translate.sorbet_sigs_to_rbs_comments(
            ruby_contents,
            file: "test.rb",
            positional_names: positional_names,
            preserve_multiline_signatures: preserve_multiline_signatures,
            max_line_length: max_line_length,
            translate_generics: translate_generics,
            translate_helpers: translate_helpers,
            translate_abstract_methods: translate_abstract_methods,
          )
        end
      end
    end
  end
end
