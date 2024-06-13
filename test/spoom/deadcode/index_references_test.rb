# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    class IndexReferencesTest < Spoom::TestWithProject
      include Test::Helpers::DeadcodeHelper

      def test_index_constant_references
        @project.write!("foo.rb", <<~RB)
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
          C14::NOT_INDEXED = 42 # The last one is not indexed, it's an assignment
          C15::C16 << 42
          C17::C18 += 42
          C19::C20 ||= 42
          C21::C22 &&= 42
          puts "\#{C23}"

          ::NOT_INDEXED = 42 # Not indexed, it's an assignment
          puts "NOT_INDEXED_STRING"
          puts :NOT_INDEXED_SYMBOL
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
          deadcode_index.all_references.select(&:constant?).map(&:name).sort_by { |n| n.delete_prefix("C").to_i },
        )
      end

      def test_index_constant_references_value
        @project.write!("foo.rb", <<~RB)
          C1 = C2
          C1 = [C3::C4]
          C1 << C5
          C1 += C6
          C1 ||= C7
          C1 &&= C8
          C1[C9] = C10
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
          ],
          deadcode_index.all_references.select(&:constant?).map(&:name).uniq.sort_by { |n| n.delete_prefix("C").to_i },
        )
      end

      def test_index_class_references
        @project.write!("foo.rb", <<~RB)
          C1.new

          class X1 < ::C2; end
          class X2 < C3; end
          class X3 < C4::C5; end
        RB

        assert_equal(
          ["C1", "C2", "C3", "C4", "C5"],
          deadcode_index.all_references.select(&:constant?).map(&:name).sort,
        )
      end

      def test_index_module_references
        @project.write!("foo.rb", <<~RB)
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
          ["M1", "M10", "M11", "M12", "M13", "M14", "M15", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9"],
          deadcode_index.all_references.select(&:constant?).map(&:name).sort,
        )
      end

      def test_index_method_references
        @project.write!("foo.rb", <<~RB)
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

          !m27 # The `!` is indexed and will count as one more reference
          m28&.m29
          m30(&m32)
          m32 { m33 }
          m34 do m35 end
          m36[m37] # The `[]` is indexed and will count as one more reference

          def foo(&block)
            m38(&block)
          end

          m39(&:m40)
          m41(&m42)
          m43(m44, &m45(m46))
          m47, m48 = Foo.m49
        RB

        references = deadcode_index.all_references.select(&:method?)
        assert_equal(51, references.size) # +2 including `[]` and `!`

        references.each do |ref|
          case ref.name
          when "[]", "!"
            next
          else
            assert(ref.name =~ /^m(\d+)(=)?$/)
          end
        end
      end

      def test_index_method_assign_references
        @project.write!("foo.rb", <<~RB)
          m1= 42
          m2=(42)
          m3 = m4.m5
          m6.m7.m8 = m9.m10
          @c.m11 = 42
          m12, m13 = 42
        RB

        assert_equal(
          ["m10", "m11=", "m12=", "m13=", "m1=", "m2=", "m3=", "m4", "m5", "m6", "m7", "m8=", "m9"],
          deadcode_index.all_references.map(&:name).sort,
        )
      end

      def test_index_method_opassign_references
        @project.write!("foo.rb", <<~RB)
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
            "m10",
            "m11",
            "m12",
            "m12=",
            "m13",
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
          ],
          deadcode_index.all_references.map(&:name).sort,
        )
      end

      def test_index_method_keyword_arguments_references
        @project.write!("foo.rb", <<~RB)
          m1.m2(dead: 42, m3:)
        RB

        assert_equal(
          ["m1", "m2", "m3"],
          deadcode_index.all_references.map(&:name).sort,
        )
      end

      def test_index_method_forward_references
        @project.write!("foo.rb", <<~RB)
          def foo(...)
            bar(...)
          end
        RB

        assert_equal(
          ["bar"],
          deadcode_index.all_references.map(&:name).sort,
        )
      end

      def test_index_method_operators
        @project.write!("foo.rb", <<~RB)
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

        references = deadcode_index.all_references
          .select(&:method?)
          .map(&:name)
          .sort
          .uniq

        assert_equal(
          [
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
            "x",
            "|",
            "||",
          ],
          references,
        )
      end
    end
  end
end
