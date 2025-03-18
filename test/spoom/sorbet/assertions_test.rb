# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class AssertionsTest < Minitest::Test
      # T.let assertions

      def test_translate_ignore_non_assigns
        rb = <<~RB
          T.let(42, Integer)
          ::T.let(nil, String)
          T.cast(ARGV.first, String)
        RB

        assert_equal(rb, rbi_to_rbs(rb))
      end

      def test_translate_ignore_non_assertions
        rb = <<~RB
          ignored1 = 42
          ignored2 = T.let
          ignored3 = T::T.let(nil, T.nilable(String))
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

      def test_translate_assigns_with_parentheses
        rb = <<~RB
          (@x = T.let(@x, T.nilable(String)))
        RB

        assert_equal(<<~RB, rbi_to_rbs(rb))
          (@x = @x) #: String?
        RB
      end

      def test_translate_assigns_with_dangling_conditionals
        rb = <<~RB
          x = T.let(42, Integer) if foo
        RB

        assert_equal(<<~RB, rbi_to_rbs(rb))
          x = 42 if foo #: Integer
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
          c = [
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

        assert_equal(rb, rbi_to_rbs(rb))
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

      def test_translate_none
        rb = <<~RB
          a = T.let(nil, T.nilable(String))
          b = T.cast(ARGV.first, String)
          c = T.must(ARGV.first)
        RB

        assert_equal(rb, rbi_to_rbs(rb, let: false, cast: false, must: false))
      end

      def test_translate_only_let
        rb = <<~RB
          a = T.let(nil, T.nilable(String))
          b = T.cast(ARGV.first, String)
          c = T.must(ARGV.first)
        RB

        assert_equal(<<~RB, rbi_to_rbs(rb, let: true, cast: false, must: false))
          a = nil #: String?
          b = T.cast(ARGV.first, String)
          c = T.must(ARGV.first)
        RB
      end

      def test_translate_only_cast
        rb = <<~RB
          a = T.let(nil, T.nilable(String))
          b = T.cast(ARGV.first, String)
          c = T.must(ARGV.first)
        RB

        assert_equal(<<~RB, rbi_to_rbs(rb, let: false, cast: true, must: false))
          a = T.let(nil, T.nilable(String))
          b = ARGV.first #: as String
          c = T.must(ARGV.first)
        RB
      end

      def test_translate_only_must
        rb = <<~RB
          a = T.let(nil, T.nilable(String))
          b = T.cast(ARGV.first, String)
          c = T.must(ARGV.first)
        RB

        assert_equal(<<~RB, rbi_to_rbs(rb, let: false, cast: false, must: true))
          a = T.let(nil, T.nilable(String))
          b = T.cast(ARGV.first, String)
          c = ARGV.first #: as !nil
        RB
      end

      def test_translate_all
        rb = <<~RB
          a = T.let(nil, T.nilable(String))
          b = T.cast(ARGV.first, String)
          c = T.must(ARGV.first)
        RB

        assert_equal(<<~RB, rbi_to_rbs(rb, let: true, cast: true, must: true))
          a = nil #: String?
          b = ARGV.first #: as String
          c = ARGV.first #: as !nil
        RB
      end

      private

      #: (String, ?let: bool, ?cast: bool, ?must: bool) -> String
      def rbi_to_rbs(ruby_contents, let: true, cast: true, must: true)
        Assertions.rbi_to_rbs(ruby_contents, file: "foo.rb", let: let, cast: cast, must: must)
      end
    end
  end
end
