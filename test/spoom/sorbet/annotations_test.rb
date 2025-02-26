# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class AnnotationsTest < Minitest::Test
      def test_translate_ignore_non_assigns
        rb = <<~RB
          T.let(42, Integer)
          ::T.let(nil, String)
        RB

        assert_equal(rb, rbi_to_rbs(rb))
      end

      def test_translate_ignore_non_annotations
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
        rb = <<~RBI
          @@a = T.let(nil, T.nilable(String))
          @@b = ::T.let(nil, T.nilable(String))
          @@c ||= T.let(nil, T.nilable(String))
          @@d &&= T.let(nil, T.nilable(String))
          @@e += T.let(nil, T.nilable(String))
        RBI

        assert_equal(<<~RB, rbi_to_rbs(rb))
          @@a = nil #: String?
          @@b = nil #: String?
          @@c ||= nil #: String?
          @@d &&= nil #: String?
          @@e += nil #: String?
        RB
      end

      def test_translate_assigns_constants
        rb = <<~RBI
          A = T.let(nil, T.nilable(String))
          B = ::T.let(nil, T.nilable(String))
          C ||= T.let(nil, T.nilable(String))
          D &&= T.let(nil, T.nilable(String))
          E += T.let(nil, T.nilable(String))
        RBI

        assert_equal(<<~RB, rbi_to_rbs(rb))
          A = nil #: String?
          B = nil #: String?
          C ||= nil #: String?
          D &&= nil #: String?
          E += nil #: String?
        RB
      end

      def test_translate_assigns_constant_paths
        rb = <<~RBI
          ::A = ::T.let(nil, T.nilable(String))
          B::C = T.let(nil, T.nilable(String))
          ::D ||= T.let(nil, T.nilable(String))
          ::E &&= T.let(nil, T.nilable(String))
          ::F += T.let(nil, T.nilable(String))
        RBI

        assert_equal(<<~RB, rbi_to_rbs(rb))
          ::A = nil #: String?
          B::C = nil #: String?
          ::D ||= nil #: String?
          ::E &&= nil #: String?
          ::F += nil #: String?
        RB
      end

      def test_translate_assigns_global_variables
        rb = <<~RBI
          $a = T.let(nil, T.nilable(String))
          $b = ::T.let(nil, T.nilable(String))
          $c ||= T.let(nil, T.nilable(String))
          $d &&= T.let(nil, T.nilable(String))
          $e += T.let(nil, T.nilable(String))
        RBI

        assert_equal(<<~RB, rbi_to_rbs(rb))
          $a = nil #: String?
          $b = nil #: String?
          $c ||= nil #: String?
          $d &&= nil #: String?
          $e += nil #: String?
        RB
      end

      def test_translate_assigns_instance_variables
        rb = <<~RBI
          @a = T.let(nil, T.nilable(String))
          @b = ::T.let(nil, T.nilable(String))
          @c ||= T.let(nil, T.nilable(String))
          @d &&= T.let(nil, T.nilable(String))
          @e += T.let(nil, T.nilable(String))
        RBI

        assert_equal(<<~RB, rbi_to_rbs(rb))
          @a = nil #: String?
          @b = nil #: String?
          @c ||= nil #: String?
          @d &&= nil #: String?
          @e += nil #: String?
        RB
      end

      def test_translate_assigns_local_variables
        rb = <<~RBI
          a = T.let(nil, T.nilable(String))
          b = ::T.let(nil, T.nilable(String))
          c ||= T.let(nil, T.nilable(String))
          d &&= T.let(nil, T.nilable(String))
          e += T.let(nil, T.nilable(String))
        RBI

        assert_equal(<<~RB, rbi_to_rbs(rb))
          a = nil #: String?
          b = nil #: String?
          c ||= nil #: String?
          d &&= nil #: String?
          e += nil #: String?
        RB
      end

      def test_translate_assigns_with_indented_values
        rb = <<~RBI
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
        RBI

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

      private

      #: (String) -> String
      def rbi_to_rbs(ruby_contents)
        Annotations.rbi_to_rbs(ruby_contents, file: "foo.rb")
      end
    end
  end
end
