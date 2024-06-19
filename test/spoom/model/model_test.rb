# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Model
    class ModelTest < Minitest::Test
      extend T::Sig

      def test_symbol_nesting
        model = model(<<~RB)
          module Foo
            class Bar
              class Baz; end
              class Baz::Qux; end
            end
          end

          class Bar::Baz
            class << self; end
          end
        RB

        assert_equal(
          [
            ["Foo"],
            ["Foo", "Bar"],
            ["Foo", "Bar", "Baz"],
            ["Foo", "Bar", "Baz::Qux"],
            ["Bar::Baz"],
            ["Bar::Baz", "<Class:Bar::Baz>"],
          ],
          model.symbols.flat_map do |_name, symbol|
            symbol.definitions.filter_map do |symbol_def|
              next unless symbol_def.is_a?(Namespace)

              symbol_def.nesting
            end
          end,
        )
      end

      def test_resolve_symbol_in_nested_namespaces
        model = model(<<~RB)
          module Foo
            class Bar
              class Baz; end
            end
          end
        RB

        context = ["Foo"]
        assert_equal(model["Foo"], model.resolve_symbol("::Foo", context: context))
        assert_equal(model["Foo"], model.resolve_symbol("Foo", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Bar", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Foo::Bar", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Bar::Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Foo::Bar::Baz", context: context))

        context = ["Foo", "Bar"]
        assert_equal(model["Foo"], model.resolve_symbol("::Foo", context: context))
        assert_equal(model["Foo"], model.resolve_symbol("Foo", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Bar", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Foo::Bar", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Bar::Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Foo::Bar::Baz", context: context))

        context = ["Foo", "Bar", "Baz"]
        assert_equal(model["Foo"], model.resolve_symbol("::Foo", context: context))
        assert_equal(model["Foo"], model.resolve_symbol("Foo", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Bar", context: context))
        assert_equal(model["Foo::Bar"], model.resolve_symbol("Foo::Bar", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Bar::Baz", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Foo::Bar::Baz", context: context))

        context = ["Foo"]
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("Qux", context: context))
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("::Bar", context: context))
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("::Baz", context: context))
      end

      def test_resolve_symbol_in_compact_namespaces
        model = model(<<~RB)
          module Foo::Bar
            class Baz; end
          end
        RB

        context = ["Foo::Bar"]

        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("::Foo", context: context))
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("Foo", context: context))
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("Bar", context: context))
        assert_instance_of(UnresolvedSymbol, model.resolve_symbol("Bar::Baz", context: context))

        assert_equal(model["Foo::Bar"], model.resolve_symbol("Foo::Bar", context: context))
        assert_equal(model["Foo::Bar::Baz"], model.resolve_symbol("Baz", context: context))
      end

      def test_resolve_symbol_from_another_namespace
        model = model(<<~RB)
          C = 1

          module Foo
            C = 42
          end

          class Foo::Bar
          end
        RB

        context = ["Foo::Bar"]
        assert_equal(model["C"], model.resolve_symbol("::C", context: context))
        assert_equal(model["C"], model.resolve_symbol("C", context: context))
      end

      def test_resolve_symbol_from_nesting_namespace
        model = model(<<~RB)
          C = 1

          module Foo
            C = 42

            class Bar
            end
          end
        RB

        context = ["Foo", "Bar"]
        assert_equal(model["C"], model.resolve_symbol("::C", context: context))
        assert_equal(model["Foo::C"], model.resolve_symbol("C", context: context))
      end

      def test_resolve_symbol_from_singleton_class
        model = model(<<~RB)
          C = 1

          module Foo
            class << self
            end
          end

          class Bar
            class << self
              C = 2
            end
          end
        RB

        context = ["<Class:Foo>"]
        assert_equal(model["C"], model.resolve_symbol("::C", context: context))
        assert_equal(model["C"], model.resolve_symbol("C", context: context))

        context = ["<Class:Bar>"]
        assert_equal(model["<Class:Bar>::C"], model.resolve_symbol("C", context: context))
      end

      def test_resolve_symbol_from_namespaces
        model = model(<<~RB)
          C = 1

          module Foo
            class << self
            end
          end

          class Bar
            class << self
              C = 2
            end
          end
        RB

        namespace = T.cast(model["<Class:Foo>"].definitions.first, Namespace)
        assert_equal(model["C"], namespace.resolve_symbol(model, "::C"))
        assert_equal(model["C"], namespace.resolve_symbol(model, "C"))

        namespace = T.cast(model["<Class:Bar>"].definitions.first, Namespace)
        assert_equal(model["C"], namespace.resolve_symbol(model, "::C"))
        assert_equal(model["<Class:Bar>::C"], namespace.resolve_symbol(model, "C"))
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

      def test_symbols_hierarchy_for_singleton_classes
        model = model(<<~RB)
          module M1; end

          module M2
            include M1
          end

          module M3
            include M2
            extend M2
          end

          module M4
            include M2

            class << self
              include M3
            end
          end
        RB

        model.symbols_hierarchy.show_dot(transitive: false)

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

      def test_linearization
        model = model(<<~RB)
          module M1; end

          module M2
            prepend M1
          end
        RB

        p model.linearization_of(model["M2"]).map(&:full_name)
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
