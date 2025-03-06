# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Model
    class ReferencesVisitorTest < Minitest::Test
      def test_visit_constant_references
        refs = visit(<<~RB)
          puts C1
          puts C2::C3::C4
          puts foo::C5
          puts C6.foo
          foo = C7
          C8 << 42
          C9 += 42
          C10 ||= 42
          C11 &&= 42
          C12[C13]
          C14::IGNORED1 = 42 # IGNORED1 is an assignment
          C15::C16 << 42
          C17::C18 += 42
          C19::C20 ||= 42
          C21::C22 &&= 42
          puts "\#{C23}"

          ::IGNORED2 = 42 # IGNORED2 is an assignment
          puts "IGNORED3"
          puts :IGNORED4
        RB

        assert_equal(
          [
            "C1",
            "C2",
            "C3",
            "C4",
            "C5",
            "C6",
            "C7",
            "C8",
            "C9",
            "C10",
            "C11",
            "C12",
            "C13",
            "C14",
            "C15",
            "C16",
            "C17",
            "C18",
            "C19",
            "C20",
            "C21",
            "C22",
            "C23",
          ],
          refs.select(&:constant?).map(&:name),
        )
      end

      def test_visit_constant_references_value
        refs = visit(<<~RB)
          IGNORED1 = C1
          IGNORED2 = [C2::C3]
          C4 << C5
          C6 += C7
          C8 ||= C9
          C10 &&= C11
          C12[C13] = C14
        RB

        assert_equal(
          [
            "C1",
            "C2",
            "C3",
            "C4",
            "C5",
            "C6",
            "C7",
            "C8",
            "C9",
            "C10",
            "C11",
            "C12",
            "C13",
            "C14",
          ],
          refs.select(&:constant?).map(&:name),
        )
      end

      def test_visit_class_references
        refs = visit(<<~RB)
          C1.new

          class IGNORED < ::C2; end
          class IGNORED < C3; end
          class IGNORED < C4::C5; end
        RB

        assert_equal(
          ["C1", "C2", "C3", "C4", "C5"],
          refs.select(&:constant?).map(&:name),
        )
      end

      def test_visit_module_references
        refs = visit(<<~RB)
          module X
            include M1
            include M2::M3
            extend M4
            extend M5::M6
            prepend M7
            prepend M8::M9
          end

          M10.include M11
          M12.extend M13
          M14.prepend M15
        RB

        assert_equal(
          ["M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9", "M10", "M11", "M12", "M13", "M14", "M15"],
          refs.select(&:constant?).map(&:name),
        )
      end

      def test_visit_method_references
        refs = visit(<<~RB)
          m1
          m2(m3)
          m4 m5
          self.m6
          self.m7(m8)
          self.m9 m10
          C.m11
          C.m12(m13)
          C.m14 m15
          m16.m17
          m18.m19(m20)
          m21.m22 m23

          m24.m25.m26

          !m27 # The `!` is collected and will count as one more reference
          m28&.m29
          m30(&m32)
          m32 { m33 }
          m34 do m35 end
          m36[m37] # The `[]` is collected and will count as one more reference

          def foo(&block)
            m38(&block)
          end

          m39(&:m40)
          m41(&m42)
          m43(m44, &m45(m46))
          m47, m48 = Foo.m49
        RB

        refs = refs.select(&:method?).map(&:name)
        assert_equal(51, refs.size) # 49 + 2 (including `[]` and `!`)

        refs.each do |ref|
          assert(ref =~ /^(m(\d+)(=)?)|\[\]|!$/)
        end
      end

      def test_visit_method_assign_references
        refs = visit(<<~RB)
          m1= 42
          m2=(42)
          m3 = m4.m5
          m6.m7.m8 = m9.m10
          @c.m11 = 42
          m12, m13 = 42
        RB

        assert_equal(
          ["m1=", "m2=", "m3=", "m4", "m5", "m6", "m7", "m8=", "m9", "m10", "m11=", "m12=", "m13="],
          refs.select(&:method?).map(&:name),
        )
      end

      def test_visit_method_opassign_references
        refs = visit(<<~RB)
          m1 += 42
          m2 |= 42
          m3 ||= 42
          m4 &&= 42
          m5.m6 += m7
          m8.m9 ||= m10
          m11.m12 &&= m13
        RB

        assert_equal(
          [
            "m1",
            "m1=",
            "m2",
            "m2=",
            "m3",
            "m3=",
            "m4",
            "m4=",
            "m5",
            "m6",
            "m6=",
            "m7",
            "m8",
            "m9",
            "m9=",
            "m10",
            "m11",
            "m12",
            "m12=",
            "m13",
          ],
          refs.select(&:method?).map(&:name),
        )
      end

      def test_visit_method_keyword_arguments_references
        refs = visit(<<~RB)
          m1.m2(dead: 42, m3:)
        RB

        assert_equal(
          ["m1", "m2", "m3"],
          refs.select(&:method?).map(&:name),
        )
      end

      def test_visit_method_forward_references
        refs = visit(<<~RB)
          def foo(...)
            bar(...)
          end
        RB

        assert_equal(
          ["bar"],
          refs.select(&:method?).map(&:name),
        )
      end

      def test_visit_method_operators
        refs = visit(<<~RB)
          x != x
          x % x
          x & x
          x && x
          x * x
          x ** x
          x + x
          x - x
          x / x
          x << x
          x == x
          x === x
          x >> x
          x ^ x
          x | x
          x || x
        RB

        assert_equal(
          [
            "x",
            "!=",
            "%",
            "&",
            "&&",
            "*",
            "**",
            "+",
            "-",
            "/",
            "<<",
            "==",
            "===",
            ">>",
            "^",
            "|",
            "||",
          ],
          refs.select(&:method?).map(&:name).uniq,
        )
      end

      private

      def visit(code)
        node = Spoom.parse_ruby(code, file: "-")

        v = ReferencesVisitor.new("-")
        v.visit(node)
        v.references
      end
    end
  end
end
