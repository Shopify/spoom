# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    # Equivalent to resolver - 5000 phase in Sorbet
    class Resolver < Visitor
      extend T::Sig

      class Error < Typecheck::Error; end

      class Result < T::Struct
        prop :errors, T::Array[Error], default: []
      end

      class << self
        extend T::Sig

        sig { params(model: Model, parsed_files: T::Array[[String, Prism::Node]]).returns(Result) }
        def run(model, parsed_files)
          result = Result.new

          parsed_files.each do |file, node|
            resolver = Spoom::Typecheck::Resolver.new(model, file)
            resolver.visit(node)
            result.errors.concat(resolver.errors)
          end

          result
        end
      end

      sig { returns(T::Array[Error]) }
      attr_reader(:errors)

      sig { params(model: Model, file: String).void }
      def initialize(model, file)
        super()

        @model = model
        @file = file
        @errors = T.let([], T::Array[Error])
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        symbol_def = node.spoom_symbol_def
        raise error("Missing symbol def for `#{node.name}`", node) unless symbol_def.is_a?(Model::Method)

        sig = symbol_def.sigs.first
        if sig
          resolver = SigResolver.new(@model, symbol_def)
          resolver.visit_sig(sig)
          @errors.concat(resolver.errors)
        end

        super
      end

      sig { override.params(node: Prism::ConstantReadNode).void }
      def visit_constant_read_node(node)
        symbol = node.spoom_symbol
        raise error("Missing unresolved def for `#{node.slice}`", node) unless symbol.is_a?(Model::UnresolvedRef)

        node.spoom_symbol = @model.resolve_symbol(
          symbol.full_name,
          context: symbol.context&.symbol,
        )

        if node.spoom_symbol.is_a?(Model::UnresolvedSymbol)
          @errors << error("Unable to resolve constant `#{node.slice}`", node)
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

      sig { override.params(node: Prism::ConstantPathWriteNode).void }
      def visit_constant_path_write_node(node)
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

        super
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

    class SigResolver < RBI::Type::Visitor
      extend T::Sig

      sig { returns(T::Array[Error]) }
      attr_reader :errors

      sig { params(model: Model, method: Model::Method).void }
      def initialize(model, method)
        super()

        @model = model
        @method = method
        @errors = T.let([], T::Array[Resolver::Error])
      end

      sig { params(sig: RBI::Sig).void }
      def visit_sig(sig)
        sig.params.each do |param|
          visit(param.type)
        end
        visit(sig.return_type)
      end

      sig { override.params(type: RBI::Type::Simple).void }
      def visit_simple(type)
        symbol = @model.resolve_symbol(type.name, context: @method.owner&.symbol)
        type.spoom_symbol = symbol

        if symbol.is_a?(Model::UnresolvedSymbol)
          @errors << Resolver::Error.new("Unresolved symbol `#{type.name}`", @method.location)
        end

        type.instance_variable_set(:@orig_name, type.name)
        type.instance_variable_set(:@name, symbol.full_name)
      end
    end
  end
end
