# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Model
    class BuilderTest < Minitest::Test
      extend T::Sig

      def test_empty
        model = model("")

        assert_empty(model.symbols)
      end

      def test_raises_when_symbol_not_found
        model = model("")

        assert_raises(Model::Error) do
          model["Foo"]
        end
      end

      def test_symbol_definitions
        model = model(<<~RB)
          class C1; end

          class C1
            class C2; end
          end

          class C1::C2; end

          class C1
            class ::C1::C2; end
          end
        RB

        assert_equal(
          ["foo.rb:1:0-1:13", "foo.rb:3:0-5:3", "foo.rb:9:0-11:3"],
          model["C1"].definitions.map(&:location).map(&:to_s),
        )

        assert_equal(
          ["foo.rb:4:2-4:15", "foo.rb:7:0-7:17", "foo.rb:10:2-10:21"],
          model["C1::C2"].definitions.map(&:location).map(&:to_s),
        )
      end

      def test_class_names
        model = model(<<~RB)
          class C1
            class C2; end
            class ::C3; end
            class C4::C5; end
          end

          class ::C6; end
          class C7::C8; end
          class ::C9::C10; end
        RB

        assert_equal(
          ["C1", "C2", "C3", "C5", "C6", "C8", "C10"],
          model.symbols.values.map(&:name),
        )
        assert_equal(
          ["C1", "C1::C2", "C3", "C1::C4::C5", "C6", "C7::C8", "C9::C10"],
          model.symbols.values.map(&:full_name),
        )
      end

      def test_class_superclass_names
        model = model(<<~RB)
          class C1 < A; end
          class C1 < ::B; end
        RB

        assert_equal(["A", "::B"], model["C1"].definitions.map { |c| T.cast(c, Class).superclass_name })
      end

      def test_mixin_names
        model = model(<<~RB)
          class C1
            include M1
            prepend ::M2
          end

          class C1
            extend M3
          end

          module M2
            include M1, M3
            include ignored1
          end

          include ignored2
        RB

        assert_equal(
          [
            "C1: Include(M1), Prepend(::M2)",
            "C1: Extend(M3)",
            "M2: Include(M1), Include(M3)",
          ],
          model.symbols.values
            .flat_map(&:definitions)
            .filter { |d| d.is_a?(Namespace) }
            .map do |d|
              "#{d.full_name}: #{T.cast(d, Namespace).mixins.map { |m| "#{class_name(m)}(#{m.name})" }.join(", ")}"
            end,
        )
      end

      def test_module_names
        model = model(<<~RB)
          module M1
            module M2; end
            module ::M3; end
            module M4::M5; end
          end

          module ::M6; end
          module M7::M8; end
          module ::M9::M10; end
        RB

        assert_equal(
          ["M1", "M2", "M3", "M5", "M6", "M8", "M10"],
          model.symbols.values.map(&:name),
        )
        assert_equal(
          ["M1", "M1::M2", "M3", "M1::M4::M5", "M6", "M7::M8", "M9::M10"],
          model.symbols.values.map(&:full_name),
        )
      end

      def test_constant_names
        model = model(<<~RB)
          A = 1

          module M
            B = 2
          end

          M::C = 3

          class C
            D = 3

            module M
              E = 4
            end

            ::F = 5
            ::G::H = 6
            M::I = 7
          end
        RB

        assert_equal(
          ["A", "M::B", "M::C", "C::D", "C::M::E", "F", "G::H", "C::M::I"],
          model.symbols.values
            .flat_map(&:definitions)
            .filter { |d| d.is_a?(Constant) }
            .map(&:full_name),
        )
      end

      def test_methods
        model = model(<<~RB)
          def m1; end
          def self.m2; end
          def C1.ignored; end
          def C1::ignored; end

          class C1
            def m3; end
            def self.m4; end

            class << self
              def m5; end
              def self.m6; end
            end
          end
        RB

        assert_equal(
          ["m1", "m2", "C1::m3", "C1::m4", "C1::m5", "C1::m6"],
          model.symbols.values
            .flat_map(&:definitions)
            .filter { |d| d.is_a?(Method) }
            .map(&:full_name),
        )
      end

      def test_attrs
        model = model(<<~RB)
          attr_reader :a1
          attr_writer :a2
          attr_accessor :a3, :a4

          class C1
            attr_reader :a5
            attr_writer :a6
          end

          class C1
            self.attr_reader :a7
            self.attr_writer :a8
            self.attr_accessor :a9
          end

          C1.attr_reader :ignored
          C1.attr_writer :ignored
          C1.attr_accessor :ignored

          attr_reader ignored
          attr_writer ignored
          attr_accessor ignored
        RB

        assert_equal(
          [
            "AttrReader(a1)",
            "AttrWriter(a2)",
            "AttrAccessor(a3)",
            "AttrAccessor(a4)",
            "AttrReader(C1::a5)",
            "AttrWriter(C1::a6)",
            "AttrReader(C1::a7)",
            "AttrWriter(C1::a8)",
            "AttrAccessor(C1::a9)",
          ],
          model.symbols.values
            .flat_map(&:definitions)
            .filter { |d| d.is_a?(Attr) }
            .map { |d| "#{class_name(d)}(#{d.full_name})" },
        )
      end

      def test_definition_owners
        model = model(<<~RB)
          class C1
            attr_reader :p1
          end

          class C1
            class C2
              def p2; end
            end
          end

          class C1::C2
            C3 = 42
            def p3; end
          end

          class C1
            class ::C1::C2
              def p4; end
            end
          end
        RB

        assert_equal(
          [
            "C1: <root>",
            "C1::p1: C1",
            "C1::C2: C1",
            "C1::C2: <root>",
            "C1::C2::p2: C1::C2",
            "C1::C2::C3: C1::C2",
            "C1::C2::p3: C1::C2",
            "C1::C2::p4: C1::C2",
          ],
          model.symbols.values
            .flat_map(&:definitions)
            .map { |d| "#{d.full_name}: #{d.owner&.full_name || "<root>"}" }
            .uniq,
        )
      end

      def test_definition_children
        model = model(<<~RB)
          class C1
            attr_reader :p1, :p2
          end

          class C1
            class C2
              def p3; end
              C3 = 42
            end
          end
        RB

        assert_equal(
          [
            "C1: C1::p1, C1::p2",
            "C1: C1::C2",
            "C1::C2: C1::C2::p3, C1::C2::C3",
          ],
          model.symbols.values
            .flat_map(&:definitions)
            .filter { |s| s.is_a?(Namespace) }
            .map { |d| "#{d.full_name}: #{T.cast(d, Namespace).children.map(&:full_name).join(", ")}" }
            .uniq,
        )
      end

      def test_visibility
        model = model(<<~RB)
          def m1; end

          private

          def m2; end

          protected

          def m3; end

          class Foo
            def m4; end

            private

            def m5; end
          end

          module Bar
            def m6; end

            private

            class << self
              def m7; end
            end
          end
        RB

        assert_equal(
          [
            "m1: public",
            "m2: private",
            "m3: protected",
            "Foo::m4: public",
            "Foo::m5: private",
            "Bar::m6: public",
            "Bar::m7: public",
          ],
          model.symbols.values
            .flat_map(&:definitions)
            .filter { |d| d.is_a?(Method) }
            .map { |d| "#{d.full_name}: #{T.cast(d, Method).visibility.serialize}" },
        )
      end

      def test_inline_visibility
        model = model(<<~RB)
          protected def m1; end

          private

          public def m2; end

          protected

          private def m3; end

          class Foo
            private def m4; end

            def m5; end
          end

          def m6; end
        RB

        assert_equal(
          [
            "m1: protected",
            "m2: public",
            "m3: private",
            "Foo::m4: private",
            "Foo::m5: public",
            "m6: protected",
          ],
          model.symbols.values
            .flat_map(&:definitions)
            .filter { |d| d.is_a?(Method) }
            .map { |d| "#{d.full_name}: #{T.cast(d, Method).visibility.serialize}" },
        )
      end

      def test_sigs
        model = model(<<~RB)
          sig { void }
          sig { returns(Integer) }
          def m1; end

          class C1
            sig { void }
            attr_reader :p1, :p2

            sig { returns(Integer) } # discarded
          end
        RB

        assert_equal(
          [
            "m1: sig { void }, sig { returns(Integer) }",
            "C1::p1: sig { void }",
            "C1::p2: sig { void }",
          ],
          model.symbols.values
            .flat_map(&:definitions)
            .filter { |d| d.is_a?(Property) }
            .map { |d| "#{d.full_name}: #{T.cast(d, Property).sigs.map(&:string).join(", ")}" },
        )
      end

      def test_comments
        model = model(<<~RB)
          # not comment

          # comment1
          # comment2
          class C1; end

          # not comment

          # comment3
          # comment4
          module C2; end

          # not comment

          # comment5
          # comment6
          C3 = 42

          #  comment7
          C4::C5 = 42

          # not comment

          #    comment8
          def m1; end

          # not comment
        RB

        assert_equal(["comment1", "comment2"], comments_for(model, "C1"))
        assert_equal(["comment3", "comment4"], comments_for(model, "C2"))
        assert_equal(["comment5", "comment6"], comments_for(model, "C3"))
        assert_equal([" comment7"], comments_for(model, "C4::C5"))
        assert_equal(["   comment8"], comments_for(model, "m1"))
      end

      private

      #: (String rb) -> Model
      def model(rb)
        file = "foo.rb"
        node, comments = Spoom.parse_ruby_with_comments(rb, file: file)
        model = Model.new
        builder = Builder.new(model, "foo.rb", comments: comments)
        builder.visit(node)
        model
      end

      #: (Object obj) -> String
      def class_name(obj)
        T.must(obj.class.name&.split("::")&.last)
      end

      #: (Model model, String symbol_name) -> Array[String]
      def comments_for(model, symbol_name)
        T.must(model.symbols[symbol_name]).definitions.map(&:comments).flatten.map(&:string)
      end
    end
  end
end
