# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    class IndexDefinitionsTest < Spoom::TestWithProject
      include Test::Helpers::DeadcodeHelper

      def test_index_rescue_parser_error
        @project.write!("foo.rb", <<~RB)
          def foo(
        RB

        exception = assert_raises(ParseError) do
          deadcode_index
        end

        assert_equal(<<~ERRORS, exception.message)
          Error while parsing foo.rb:
          - expected a `)` to close the parameters (at 1:8)
          - cannot parse the expression (at 1:8)
          - expected an `end` to close the `def` statement (at 1:8)
        ERRORS
      end

      def test_index_constant_definitions
        @project.write!("foo.rb", <<~RB)
          C1 = 42
          ::C2 = 42
          NOT_INDEXED::C3 = 42
          not_indexed::C4 = 42
          C5, C6 = 42
          ::C7, ::C8 = 42

          NOT_INDEXED.foo = 42

          @NOT_INDEXED = 42
          not_indexed[:NOT_INDEXED][:NOT_INDEXED] = 42
          NOT_INDEXED += 42
          NOT_INDEXED << 42
        RB

        assert_equal(
          ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
          deadcode_index.all_definitions.select(&:constant?).map(&:name),
        )
      end

      def test_index_class_definitions
        @project.write!("foo.rb", <<~RB)
          class C1; end
          class ::C2; end
          class NOT_INDEXED::C3; end
          class not_indexed::C4; end

          class C5 < NOT_INDEXED
            class C6; end
          end
        RB

        assert_equal(
          ["C1", "C2", "C3", "C4", "C5", "C6"],
          deadcode_index.all_definitions.select(&:class?).map(&:name),
        )
      end

      def test_index_module_definitions
        @project.write!("foo.rb", <<~RB)
          module M1; end
          module ::M2; end
          module NOT_INDEXED::M3; end
          module not_indexed::M4; end

          module M5
            module M6; end
          end
        RB

        assert_equal(
          ["M1", "M2", "M3", "M4", "M5", "M6"],
          deadcode_index.all_definitions.select(&:module?).map(&:name),
        )
      end

      def test_index_method_definitions
        @project.write!("foo.rb", <<~RB)
          def m1; end
          def self.m2; end
          def NOT_INDEXED::m3; end
          def not_indexed::m4; end
          def not_indexed.m5; end

          def m6(); end
          def m7(x, y, z); end

          def m8 = 42

          def m9=(x); end

          def `; end
          def !; end
          def <=>; end
          def CONST; end
        RB

        assert_equal(
          ["m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9=", "`", "!", "<=>", "CONST"],
          deadcode_index.all_definitions.select(&:method?).map(&:name),
        )
      end

      def test_index_attribute_definitions
        @project.write!("foo.rb", <<~RB)
          attr_reader :r1
          attr_reader :r2, :r3
          attr_reader(:r4, :r5)
          self.attr_reader :r6
          self.attr_reader(:r7)

          attr_writer :w1
          attr_writer :w2, :w3
          attr_writer(:w4, :w5)
          self.attr_writer :w6
          self.attr_writer(:w7)

          attr_accessor :a1
          attr_accessor :a2, :a3
          attr_accessor(:a4, :a5)
          self.attr_accessor :a6
          self.attr_accessor(:a7)
        RB

        index = deadcode_index

        assert_equal(
          ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "r1", "r2", "r3", "r4", "r5", "r6", "r7"],
          index.all_definitions.select(&:attr_reader?).map(&:name).sort,
        )

        assert_equal(
          ["a1=", "a2=", "a3=", "a4=", "a5=", "a6=", "a7=", "w1=", "w2=", "w3=", "w4=", "w5=", "w6=", "w7="],
          index.all_definitions.select(&:attr_writer?).map(&:name).sort,
        )
      end

      def test_index_attribute_definitions_but_ignore_when_not_a_symbol
        @project.write!("foo.rb", <<~RB)
          attr_reader :r1
          attr_reader "foo"
          attr_reader *names
        RB

        assert_equal(
          ["r1"],
          deadcode_index.all_definitions.select(&:attr_reader?).map(&:name),
        )
      end

      def test_index_method_splats
        @project.write!("foo.rb", <<~RB)
          def foo(*args, **kwargs, &block)
            bar(*args, **kwargs, &block)
          end
        RB

        assert_equal(
          ["foo"],
          deadcode_index.all_definitions.select(&:method?).map(&:name).sort,
        )
      end

      def test_index_method_forward_definitions
        @project.write!("foo.rb", <<~RB)
          def foo(...)
            bar(...)
          end
        RB

        assert_equal(
          ["foo"],
          deadcode_index.all_definitions.select(&:method?).map(&:name).sort,
        )
      end

      def test_index_method_star_forward_definitions
        skip if RUBY_VERSION < "3.2"

        @project.write!("foo.rb", <<~RB)
          def foo(*, **, &)
            bar(*, **, &)
          end
        RB

        assert_equal(
          ["foo"],
          deadcode_index.all_definitions.select(&:method?).map(&:name).sort,
        )
      end

      def test_index_namespaces
        @project.write!("foo.rb", <<~RB)
          class A
            module B
              class C::D; end

              E = 42
              ::F = 42
              G::H::I = 42
              class ::J; end
              class J::K; end
              class ::L::M
                class N; end
              end
              module O::P; end
              module ::Q::R
                module S; end
              end

              attr_accessor :foo

              def bar; end
              def self.baz; end

              class << self
                def bla; end
              end
            end
          end

          def baz; end
        RB

        assert_equal(
          [
            "A",
            "A::B",
            "A::B::C::D",
            "A::B::E",
            "A::B::G::H::I",
            "A::B::J::K",
            "A::B::O::P",
            "A::B::bar",
            "A::B::baz",
            "A::B::bla",
            "A::B::foo",
            "A::B::foo=",
            "F",
            "J",
            "L::M",
            "L::M::N",
            "Q::R",
            "Q::R::S",
            "baz",
          ],
          deadcode_index.all_definitions.map(&:full_name).sort,
        )
      end
    end
  end
end
