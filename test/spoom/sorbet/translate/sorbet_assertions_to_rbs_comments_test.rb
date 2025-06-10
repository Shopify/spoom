# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    module Translate
      class SorbetAssertionsToRBSCommentsTest < Minitest::Test
        def test_translate_casts
          rb = <<~RB
            T.let(42, Integer)
            ::T.let(nil, String)
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            42 #: Integer
            nil #: String
          RB
        end

        def test_translate_ignore_non_assertions
          rb = <<~RB
            ignored1 = 42
            ignored2 = T.let
            ignored3 = T::T.let(nil, T.nilable(String))
            ignored4 = T.cast(nil)
            ignored5 = foo(T.let(nil, T.nilable(String)))
            @ignored6 = 42
            @@ignored7 = 42
            $ignored8 = 42
            IGNORED9 = 42
          RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_translate_assigns_class_variables
          rb = <<~RB
            @@a = T.let(nil, T.nilable(String))
            @@b = ::T.let(nil, T.nilable(String))
            @@c ||= T.let(nil, T.nilable(String))
            @@d &&= T.let(nil, T.nilable(String))
            @@e += T.let(nil, T.nilable(String))
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            @@a = nil #: String?
            @@b = nil #: String?
            @@c ||= nil #: String?
            @@d &&= nil #: String?
            @@e += nil #: String?
          RB
        end

        def test_translate_assigns_constants
          rb = <<~RB
            A = T.let(nil, T.nilable(String))
            B = ::T.let(nil, T.nilable(String))
            C ||= T.let(nil, T.nilable(String))
            D &&= T.let(nil, T.nilable(String))
            E += T.let(nil, T.nilable(String))
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            A = nil #: String?
            B = nil #: String?
            C ||= nil #: String?
            D &&= nil #: String?
            E += nil #: String?
          RB
        end

        def test_translate_assigns_constant_paths
          rb = <<~RB
            ::A = ::T.let(nil, T.nilable(String))
            B::C = T.let(nil, T.nilable(String))
            ::D ||= T.let(nil, T.nilable(String))
            ::E &&= T.let(nil, T.nilable(String))
            ::F += T.let(nil, T.nilable(String))
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            ::A = nil #: String?
            B::C = nil #: String?
            ::D ||= nil #: String?
            ::E &&= nil #: String?
            ::F += nil #: String?
          RB
        end

        def test_translate_assigns_global_variables
          rb = <<~RB
            $a = T.let(nil, T.nilable(String))
            $b = ::T.let(nil, T.nilable(String))
            $c ||= T.let(nil, T.nilable(String))
            $d &&= T.let(nil, T.nilable(String))
            $e += T.let(nil, T.nilable(String))
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            $a = nil #: String?
            $b = nil #: String?
            $c ||= nil #: String?
            $d &&= nil #: String?
            $e += nil #: String?
          RB
        end

        def test_translate_assigns_instance_variables
          rb = <<~RB
            @a = T.let(nil, T.nilable(String))
            @b = ::T.let(nil, T.nilable(String))
            @c ||= T.let(nil, T.nilable(String))
            @d &&= T.let(nil, T.nilable(String))
            @e += T.let(nil, T.nilable(String))
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            @a = nil #: String?
            @b = nil #: String?
            @c ||= nil #: String?
            @d &&= nil #: String?
            @e += nil #: String?
          RB
        end

        def test_translate_assigns_local_variables
          rb = <<~RB
            a = T.let(nil, T.nilable(String))
            b = ::T.let(nil, T.nilable(String))
            c ||= T.let(nil, T.nilable(String))
            d &&= T.let(nil, T.nilable(String))
            e += T.let(nil, T.nilable(String))
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            a = nil #: String?
            b = nil #: String?
            c ||= nil #: String?
            d &&= nil #: String?
            e += nil #: String?
          RB
        end

        def test_translate_multi_assigns
          rb = <<~RB
            @@a, @@b = T.let(nil, T.nilable(String))
            A, B = T.let(nil, T.nilable(String))
            A::B, C::D = T.let(nil, T.nilable(String))
            $a, $b = T.let(nil, T.nilable(String))
            @a, @b = T.let(nil, T.nilable(String))
            a, b = T.let(nil, T.nilable(String))
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            @@a, @@b = nil #: String?
            A, B = nil #: String?
            A::B, C::D = nil #: String?
            $a, $b = nil #: String?
            @a, @b = nil #: String?
            a, b = nil #: String?
          RB
        end

        def test_translate_assigns_with_indented_values
          rb = <<~RB
            a = ::T.let([
              1, 2, 3,
            ], T::Array[Integer])
            b = ::T.let(
              [
                1, 2, 3,
              ],
              T::Array[Integer],
            )
            c =
              ::T.let(
                [
                  1, 2, 3,
                ],
                T::Array[Integer],
              )
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            a = [
              1, 2, 3,
            ] #: Array[Integer]
            b = [
              1, 2, 3,
            ] #: Array[Integer]
            c =
              [
                1, 2, 3,
              ] #: Array[Integer]
          RB
        end

        def test_translate_assigns_ignore_nested_assigns
          rb = <<~RB
            def foo
              @x ||= T.let(
                begin
                  y = T.let(z, Z)
                end,
                X
              )
            end
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            def foo
              @x ||= begin
                y = T.let(z, Z)
              end #: X
            end
          RB
        end

        def test_translate_assigns_ignore_heredoc_values
          rb = <<~RB
            a = T.let(<<~STR, String)
              foo
            STR

            b = T.let(<<-STR, String)
              foo
            STR

            c = T.let(<<~STR.strip, String)
              foo
            STR

            d = T.let(foo(<<~STR), String)
              foo
            STR

            e = T.let(<<~STR.strip, String)
              \#{foo}
            STR
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            a = <<~STR #: String
              foo
            STR

            b = <<-STR #: String
              foo
            STR

            c = <<~STR.strip #: String
              foo
            STR

            d = foo(<<~STR) #: String
              foo
            STR

            e = <<~STR.strip #: String
              \#{foo}
            STR
          RB
        end

        def test_translate_assigns_does_not_match_bare_strings_has_heredoc
          rb = <<~RB
            a = T.let("<<~STR", String)
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            a = "<<~STR" #: String
          RB
        end

        def test_translate_supports_encoding
          rb = <<~RB
            # 😊
            a = T.let("foo", String)
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            # 😊
            a = "foo" #: String
          RB
        end

        def test_translate_only_first_level_assertions_at_the_end_of_the_line
          rb = <<~RB
            a = T.let(T.let(b, B), A)
            foo(T.must(c))
            T.must(d).baz
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            a = T.let(b, B) #: A
            foo(T.must(c))
            T.must(d).baz
          RB
        end

        def test_translate_cast
          rb = <<~RB
            T.cast(a, A)
            b = T.cast(b, B)
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            a #: as A
            b = b #: as B
          RB
        end

        def test_translate_must
          rb = <<~RB
            T.must(a)
            b = T.must(b)
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            a #: as !nil
            b = b #: as !nil
          RB
        end

        def test_translate_unsafe
          rb = <<~RB
            T.unsafe(a)
            b = T.unsafe(b)
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            a #: as untyped
            b = b #: as untyped
          RB
        end

        def test_does_not_translate_assertions_already_with_annotations
          rb = <<~RB
            a = T.let(a, A) #: as A
            T.must(a) #: as A
          RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_does_not_translate_assigns_with_parentheses
          rb = <<~RB
            (@x = T.let(@x, T.nilable(String)))
          RB

          # TODO: should we translate this?
          # assert_equal(<<~RB, rbi_to_rbs(rb))
          #   (@x = @x) #: String?
          # RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_does_not_translate_assigns_with_dangling_conditionals
          rb = <<~RB
            x = T.let(42, Integer) if foo
          RB

          # TODO: should we translate this?
          # assert_equal(<<~RB, rbi_to_rbs(rb))
          #   x = 42 if foo #: Integer
          # RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_does_not_translate_assertions_already_with_comments
          rb = <<~RB
            a = T.let(42, Integer) # as Integer
          RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_translate_cast_in_oneliners
          rb = <<~RB
            arr.map { |x| T.must(x) }
            arr.map { |x|
              T.must(x)
            }
            arr.map { |x|
              arr.map { |x| T.must(x) }
            }
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            arr.map { |x| T.must(x) }
            arr.map { |x|
              x #: as !nil
            }
            arr.map { |x|
              arr.map { |x| T.must(x) }
            }
          RB
        end

        def test_translate_cast_in_cases
          rb = <<~RB
            case nodes.size
            when 0
              raise ArgumentError
            when 1
              T.must(nodes.first)
            else
              nodes
            end
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            case nodes.size
            when 0
              raise ArgumentError
            when 1
              nodes.first #: as !nil
            else
              nodes
            end
          RB
        end

        def test_translate_cast_in_nested_values
          rb = <<~RB
            type = case nodes.size
            when 0
              raise ArgumentError
            when 1
              T.must(nodes.first)
            else
              nodes
            end
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            type = case nodes.size
            when 0
              raise ArgumentError
            when 1
              nodes.first #: as !nil
            else
              nodes
            end
          RB
        end

        def test_inserts_cast_before_comments
          rb = <<~RB
            A = T.must(ARGV.first) #: String?

            case ARGV.first
            when String
              T.must(ARGV.first) #: String?
            end

            T.must(ARGV.first) #: String?
          RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_doesnt_translate_cast_in_parentheses
          rb = <<~RB
            if (a = T.let(nil, T.nilable(String)))
              a
            end
          RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_doesnt_translate_cast_in_string_interpolation
          rb = <<~RB
            "\#{T.must(ARGV.first)}"
          RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_doesnt_translate_in_expressions
          rb = <<~RB
            a - T.must(b)
          RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_doesnt_translate_in_ternary_expressions
          rb = <<~RB
            a = T.must(b) ? T.must(c) : T.must(d)
          RB

          assert_equal(rb, rbi_to_rbs(rb))
        end

        def test_translate_bind
          rb = <<~RB
            T.bind(self, T.class_of(String))

            T.bind(foo, String)

            before_enqueue { T.bind(self, String) }
          RB

          assert_equal(<<~RB, rbi_to_rbs(rb))
            #: self as singleton(String)

            T.bind(foo, String)

            before_enqueue { T.bind(self, String) }
          RB
        end

        private

        #: (String) -> String
        def rbi_to_rbs(ruby_contents)
          Translate.sorbet_assertions_to_rbs_comments(ruby_contents, file: "test.rb")
        end
      end
    end
  end
end
