# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Model
    class BuilderTest < Minitest::Test
      extend T::Sig

      def test_model_builder_empty
        model = model("")

        assert_empty(model.symbols)
      end

      def test_model_builder_classes
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

      def test_model_builder_modules
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

      private

      sig { params(rb: String).returns(Model) }
      def model(rb)
        node = Spoom.parse_ruby(rb, file: "foo.rb")

        model = Model.new
        builder = Builder.new(model, "foo.rb")
        builder.visit(node)
        model
      end
    end
  end
end
