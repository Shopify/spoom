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

      private

      sig { params(rb: String).returns(Model) }
      def model(rb)
        node = Spoom.parse_ruby(rb, file: "foo.rb")

        model = Model.new
        builder = Builder.new(model, "foo.rb")
        builder.visit(node)
        model.finalize!
        model
      end
    end
  end
end
