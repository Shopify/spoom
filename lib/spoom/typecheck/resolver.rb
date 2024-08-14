# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    class Resolver < Visitor
      extend T::Sig

      class Error < Typecheck::Error; end

      sig { returns(T::Array[Error]) }
      attr_reader(:errors)

      sig { params(model: Model, file: String).void }
      def initialize(model, file)
        super()

        @model = model
        @file = file
        @errors = T.let([], T::Array[Error])
      end

      sig { override.params(node: Prism::ConstantReadNode).void }
      def visit_constant_read_node(node)
        symbol = node.spoom_symbol
        raise error("Missing unresolved def", node) unless symbol.is_a?(Model::UnresolvedRef)

        node.spoom_symbol = @model.resolve_symbol(
          symbol.full_name,
          context: symbol.context&.symbol,
        )

        if node.spoom_symbol.is_a?(Model::UnresolvedSymbol)
          @errors << error("Unresolved symbol `#{node.slice}`", node)
        end

        super
      end

      sig { override.params(node: Prism::ConstantPathNode).void }
      def visit_constant_path_node(node)
        symbol = node.spoom_symbol
        raise error("Missing unresolved def", node) unless symbol.is_a?(Model::UnresolvedRef)

        node.spoom_symbol = @model.resolve_symbol(
          symbol.full_name,
          context: symbol.context&.symbol,
        )

        super
      end

      sig { override.params(node: Prism::ConstantWriteNode).void }
      def visit_constant_write_node(node)
        symbol_def = node.spoom_symbol_def
        raise error("Missing symbol def", node) unless symbol_def

        if symbol_def.is_a?(Model::Alias)
          target = symbol_def.target
          raise error("Alias already resolved for #{symbol_def}", node) unless target.is_a?(Model::UnresolvedRef)

          symbol_def.target = @model.resolve_symbol(
            target.full_name,
            context: target.context&.symbol,
          )
        end
      end

      sig { params(message: String, node: Prism::Node).returns(Error) }
      def error(message, node)
        location = node_location(node)
        Error.new(message, location)
      end

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@file, node.location)
      end
    end
  end
end
