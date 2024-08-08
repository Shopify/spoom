# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    # Equivalent to CFG - 6000 phase in Sorbet
    class CFG < Visitor
      extend T::Sig

      class MethodCFG < T::Struct
        const :symbol_def, Model::Method
        const :def_node, T.nilable(Prism::Node)
        const :cfg, Spoom::CFG
      end

      class Result < T::Struct
        prop :errors, T::Array[Error], default: []
        prop :cfgs, T::Array[MethodCFG], default: []
      end

      class << self
        extend T::Sig

        sig do
          params(
            model: Model,
            parsed_files: T::Array[[String, Prism::Node]],
          ).returns(Result)
        end
        def run(model, parsed_files)
          result = Result.new

          parsed_files.each do |file, node|
            next if file == "<payload>"
            next if file.end_with?(".rbi")

            resolver = Spoom::Typecheck::CFG.new(model, file)
            resolver.visit(node)
            result.errors.concat(resolver.errors)
            result.cfgs.concat(resolver.cfgs)
          end

          result
        end
      end

      sig { returns(T::Array[Error]) }
      attr_reader :errors

      sig { returns(T::Array[MethodCFG]) }
      attr_reader :cfgs

      sig { params(model: Model, file: String).void }
      def initialize(model, file)
        super()

        @model = model
        @file = file
        @errors = T.let([], T::Array[Error])
        @cfgs = T.let([], T::Array[MethodCFG])
      end

      sig { override.params(node: Prism::ProgramNode).void }
      def visit_program_node(node)
        super

        statements = collect_top_level_nodes(node.statements)
        builder = Spoom::CFG::Builder.new(@file)
        builder.visit_all(statements)

        main = Model::Method.new(
          @model.register_symbol("<main>"),
          owner: nil,
          location: Location.from_prism(@file, node.location),
          visibility: Model::Visibility::Public,
          is_singleton: true,
        )

        @cfgs << MethodCFG.new(symbol_def: main, cfg: builder.cfg, def_node: nil)
      rescue Typecheck::Error => e
        @errors << Error.new(e.message, Location.from_prism(@file, node.location))
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        super

        body = node.body
        return unless body

        raise unless body.is_a?(Prism::StatementsNode)

        statements = collect_top_level_nodes(body)
        builder = Spoom::CFG::Builder.new(@file)
        builder.visit_all(statements)

        symbol_def = node.spoom_symbol_def
        raise unless symbol_def.is_a?(Model::Class)

        main = Model::Method.new(
          @model.register_symbol("<main>"),
          owner: symbol_def,
          location: Location.from_prism(@file, node.location),
          visibility: Model::Visibility::Public,
          is_singleton: true,
        )

        @cfgs << MethodCFG.new(symbol_def: main, cfg: builder.cfg, def_node: nil)
      rescue Typecheck::Error => e
        @errors << Error.new(e.message, Location.from_prism(@file, node.location))
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        super

        body = node.body
        return unless body

        raise unless body.is_a?(Prism::StatementsNode)

        statements = collect_top_level_nodes(body)
        builder = Spoom::CFG::Builder.new(@file)
        builder.visit_all(statements)

        symbol_def = node.spoom_symbol_def
        raise unless symbol_def.is_a?(Model::Module)

        main = Model::Method.new(
          @model.register_symbol("<main>"),
          owner: symbol_def,
          location: Location.from_prism(@file, node.location),
          visibility: Model::Visibility::Public,
          is_singleton: true,
        )

        @cfgs << MethodCFG.new(symbol_def: main, cfg: builder.cfg, def_node: nil)
      rescue Typecheck::Error => e
        @errors << Error.new(e.message, Location.from_prism(@file, node.location))
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        symbol_def = node.spoom_symbol_def
        raise unless symbol_def.is_a?(Model::Method)

        builder = Spoom::CFG::Builder.new(@file)
        builder.visit(node)

        @cfgs << MethodCFG.new(symbol_def: symbol_def, cfg: builder.cfg, def_node: node)
      rescue Typecheck::Error => e
        @errors << Error.new(e.message, Location.from_prism(@file, node.location))
      end

      private

      sig do
        params(node: Prism::StatementsNode).returns(T::Array[Prism::Node])
      end
      def collect_top_level_nodes(node)
        node.body.select do |child|
          case child
          when Prism::ClassNode, Prism::ModuleNode, Prism::SingletonClassNode, Prism::DefNode
            false
          when Prism::CallNode
            child.arguments&.arguments&.grep(Prism::DefNode)&.empty?
          else
            true
          end
        end
      end
    end
  end
end
