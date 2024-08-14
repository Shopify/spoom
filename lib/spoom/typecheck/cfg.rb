# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    class CFG < Visitor
      extend T::Sig

      sig { returns(T::Hash[Model::Method, [Prism::Node, Spoom::CFG]]) }
      attr_reader :cfgs

      sig { params(model: Model, file: String).void }
      def initialize(model, file)
        super()

        @model = model
        @file = file
        @cfgs = T.let({}, T::Hash[Model::Method, [Prism::Node, Spoom::CFG]])
      end

      sig { override.params(node: Prism::ProgramNode).void }
      def visit_program_node(node)
        top_level_instructions = []

        super

        node.statements.body.each do |child|
          case child
          when Prism::ClassNode, Prism::ModuleNode, Prism::DefNode
            # skip
          else
            top_level_instructions << child
          end
        end

        main = Model::Method.new(
          @model.register_symbol("<main>"),
          owner: nil,
          location: Location.from_prism(@file, node.location),
          visibility: Model::Visibility::Public,
        )

        builder = Spoom::CFG::Builder.new
        builder.visit_all(top_level_instructions)

        @cfgs[main] = [node, builder.cfg]
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        symbol_def = node.spoom_symbol_def
        raise unless symbol_def.is_a?(Model::Method)

        builder = Spoom::CFG::Builder.new
        builder.visit(node)

        @cfgs[symbol_def] = [node, builder.cfg]
      end
    end
  end
end
