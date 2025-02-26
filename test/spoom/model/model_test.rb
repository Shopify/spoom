# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Model
    class ModelTest < Minitest::Test
      extend T::Sig

      def test_resolve_symbol
        model = model(<<~RB)
          module Foo
            class Bar
              class Baz; end
            end
          end
        RB

        context = model["Foo"]
        assert_equal(model["Foo"], model.resolve_symbol("::Foo", context: context))
        assert_equal(model["Foo"], model.resolve_symbol("Foo", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Bar", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Foo::Bar", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Bar::Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Foo::Bar::Baz", context: context))

        context = model["Foo::Bar"]
        assert_equal(model["Foo"], model.resolve_symbol("::Foo", context: context))
        assert_equal(model["Foo"], model.resolve_symbol("Foo", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Bar", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Foo::Bar", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Bar::Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Foo::Bar::Baz", context: context))

        context = model["Foo::Bar::Baz"]
        assert_equal(model["Foo"], model.resolve_symbol("::Foo", context: context))
        assert_equal(model["Foo"], model.resolve_symbol("Foo", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Bar", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Foo::Bar", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Bar::Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Foo::Bar::Baz", context: context))

        context = model["Foo"]
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("Qux", context: context))
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("::Bar", context: context))
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("::Baz", context: context))
      end

      def test_symbols_hierarchy_for_classes
        model = model(<<~RB)
          class A; end
          class B < A; end
          class C < B; end
          class D; end
        RB

        assert_equal(
          ["B", "C"],
          model.subtypes(model["A"]).map(&:full_name).sort,
        )

        assert_equal(
          ["A", "B"],
          model.supertypes(model["C"]).map(&:full_name).sort,
        )

        assert_empty(model.supertypes(model["D"]))
        assert_empty(model.subtypes(model["D"]))
      end

      def test_symbols_hierarchy_for_modules
        model = model(<<~RB)
          module A; end

          module B
            include A
          end

          module C
            include B
            prepend D
          end

          module D; end
          module E; end
        RB

        assert_equal(
          ["B", "C"],
          model.subtypes(model["A"]).map(&:full_name).sort,
        )

        assert_equal(
          ["A", "B", "D"],
          model.supertypes(model["C"]).map(&:full_name).sort,
        )

        assert_empty(model.supertypes(model["E"]))
        assert_empty(model.subtypes(model["E"]))
      end

      private

      #: (String rb) -> Model
      def model(rb)
        node, comments = Spoom.parse_ruby_with_comments(rb, file: "foo.rb")

        model = Model.new
        builder = Builder.new(model, "foo.rb", comments: comments)
        builder.visit(node)
        model.finalize!
        model
      end
    end
  end
end
