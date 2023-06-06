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
          C11[C12]
          C13::NOT_INDEXED = 42 # The last one is not indexed, it's an assignment
          puts "\#{C14}"

          ::NOT_INDEXED = 42 # Not indexed, it's an assignment
          puts "NOT_INDEXED_STRING"
          puts :NOT_INDEXED_SYMBOL
        RB

        assert_equal(
          ["C1", "C10", "C11", "C12", "C13", "C14", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"],
          deadcode_index.all_references.select(&:constant?).map(&:name).sort,
        )
      end

      def test_index_class_references
        @project.write!("foo.rb", <<~RB)
          C1.new

          class X < ::C2; end
          class X < C3; end
          class X < C4::C5; end
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
            extend M2
            prepend M3
          end

          M4.include M5
          M6.extend M7
          M8.prepend M9
        RB

        assert_equal(
          ["M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9"],
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

          !m27
          m28&.m29
          m30(&:m31)
          m32 { m33 }
          m34 do m35 end
          m36[m37] # The [] is indexed and will count as one more reference

          m38(&m39)

          def foo(&block)
            m40(&block)
          end
        RB

        references = deadcode_index.all_references.select(&:method?)
        assert_equal(41, references.size)

        references.each do |ref|
          next if ref.name == "[]"

          assert(ref.name =~ /^m(\d+)(=)?$/)
        end
      end

      def test_index_method_assign_references
        @project.write!("foo.rb", <<~RB)
          m1= 42
          m2=(42)
          m3 = m4.m5
          m6.m7.m8 = m9.m10
          @c.m11 = 42
        RB

        assert_equal(
          ["m10", "m11=", "m1=", "m2=", "m3=", "m4", "m5", "m6", "m7", "m8=", "m9"],
          deadcode_index.all_references.map(&:name).sort,
        )
      end

      def test_index_method_opassign_references
        @project.write!("foo.rb", <<~RB)
          m1 += 42
          m2 |= 42
          m3 ||= 42
          m4.m5 += m6
        RB

        assert_equal(
          ["m1", "m1=", "m2", "m2=", "m3", "m3=", "m4", "m5", "m5=", "m6"],
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
    end
  end
end
