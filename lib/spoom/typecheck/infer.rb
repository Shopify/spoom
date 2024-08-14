# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    class Infer < Visitor
      extend T::Sig

      class Scope
        extend T::Sig

        sig { returns(T::Hash[String, RBI::Type]) }
        attr_reader :var_types

        sig { void }
        def initialize
          @var_types = T.let({}, T::Hash[String, RBI::Type])
        end
      end

      sig { returns(T::Array[Error]) }
      attr_reader :errors

      sig { params(model: Model, method: Model::Method, node: Prism::Node, cfg: Spoom::CFG).void }
      def initialize(model, method, node, cfg)
        super()

        @model = model
        @method = method
        @node = node
        @cfg = cfg
        @errors = T.let([], T::Array[Error])
        @self_type = T.let(self_type_for(method), RBI::Type)

        # TODO: handle multiple sigs
        sig = method.symbol.definitions.grep(Model::Method).flat_map(&:sigs).first&.rbi

        scope = Scope.new
        if node.is_a?(Prism::DefNode)
          node.parameters&.child_nodes&.compact&.each do |param|
            case param
            when Prism::RequiredParameterNode, Prism::OptionalParameterNode, Prism::RestParameterNode,
                Prism::RequiredKeywordParameterNode, Prism::OptionalKeywordParameterNode, Prism::KeywordRestParameterNode,
                Prism::BlockParameterNode
              type = if sig
                param_type = sig.params.find { |p| p.name == param.name.to_s }&.type
                case param_type
                when RBI::Type
                  param_type
                when String
                  RBI::Type.parse_string(param_type)
                else
                  RBI::Type.untyped
                end
              else
                RBI::Type.untyped
              end
              param.spoom_type = type
              scope.var_types[param.name.to_s] = type
            end
          end
        end

        @scope_stack = T.let([scope], T::Array[Scope])
      end

      # CFG

      sig { void }
      def infer
        visit(@node)
        visit_cfg(@cfg)
      end

      sig { params(cfg: Spoom::CFG).void }
      def visit_cfg(cfg)
        visit_basic_block(cfg.root)
      end

      sig { params(block: Spoom::CFG::BasicBlock).void }
      def visit_basic_block(block)
        block.instructions.each do |instr|
          visit(instr)
        end

        block.outs.each do |succ|
          visit_basic_block(succ)
        end
      end

      # Nodes

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        receiver = node.receiver

        receiver_type = if receiver
          visit(receiver)
          type = receiver.spoom_type

          puts receiver.class
          raise error("Missing type", receiver) unless type

          type
        else
          @self_type
        end

        visit(node.arguments)
        visit(node.block)

        method_symbols = resolve_method_for_type(receiver_type, node.name.to_s) || []
        node.spoom_method_symbol = method_symbols.first

        sigs = method_symbols.flat_map(&:sigs)
        # TODO: support multiple sigs
        sig = sigs.first&.rbi

        node.spoom_type = if sig
          sig = resolve_signature(receiver_type, sig)
          T.cast(sig.return_type, RBI::Type)
        else
          RBI::Type.untyped
        end
      end

      sig { override.params(node: Prism::BlockNode).void }
      def visit_block_node(node)
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        node.spoom_type = RBI::Type.simple("NilClass")
      end

      sig { override.params(node: Prism::ConstantPathNode).void }
      def visit_constant_path_node(node)
        symbol = node.spoom_symbol
        raise error("Missing resolved symbol", node) unless symbol

        node.spoom_type = RBI::Type.class_of(RBI::Type.simple(symbol.full_name))
      end

      sig { override.params(node: Prism::ConstantReadNode).void }
      def visit_constant_read_node(node)
        symbol = node.spoom_symbol
        raise error("Missing resolved symbol", node) unless symbol

        node.spoom_type = RBI::Type.class_of(RBI::Type.simple(symbol.full_name))
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        # no super

        node.spoom_type = RBI::Type.simple("Symbol")
      end

      sig { override.params(node: Prism::InstanceVariableReadNode).void }
      def visit_instance_variable_read_node(node)
        node.spoom_type = RBI::Type.simple("NilClass")
      end

      sig { override.params(node: Prism::IntegerNode).void }
      def visit_integer_node(node)
        node.spoom_type = RBI::Type.class_of(
          RBI::Type.simple("Integer"),
        )
      end

      sig { override.params(node: Prism::LocalVariableReadNode).void }
      def visit_local_variable_read_node(node)
        super

        node.spoom_type = current_scope.var_types[node.name.to_s]
      end

      sig { override.params(node: Prism::LocalVariableWriteNode).void }
      def visit_local_variable_write_node(node)
        super

        assign_type = T.must(node.value.spoom_type)
        current_scope.var_types[node.name.to_s] = assign_type
        node.spoom_type = assign_type
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        node.spoom_type = RBI::Type.simple("NilClass")
      end

      private

      sig { params(recv_type: RBI::Type, sig: RBI::Sig).returns(RBI::Sig) }
      def resolve_signature(recv_type, sig)
        sig = sig.dup
        return_type = sig.return_type
        return_type = RBI::Type.parse_string(return_type) if return_type.is_a?(String)

        if return_type == RBI::Type.self_type
          sig.return_type = recv_type
        end
        if return_type == RBI::Type.attached_class
          raise "unexpected attached_class" unless recv_type.is_a?(RBI::Type::ClassOf)

          sig.return_type = recv_type.type
        end
        sig
      end

      sig { params(type: RBI::Type, name: String).returns(T.nilable(T::Array[Model::Method])) }
      def resolve_method_for_type(type, name)
        case type
        when RBI::Type.untyped
          []
        when RBI::Type::ClassOf
          inner_type = type.type
          type_symbol = @model.symbols[inner_type.to_rbi]
          raise "unknown symbol for type #{inner_type.to_rbi}" unless type_symbol

          defs = type_symbol.definitions.grep(Model::Namespace).flat_map(&:children).grep(Model::Method)
          defs.select! { |m| m.name == name }
          defs.select!(&:singleton?)
          return defs if defs.any?

          symbols = @model.supertypes(type_symbol)
          class_symbol = @model.symbols["Class"]

          if class_symbol
            symbols = [*symbols, class_symbol, *@model.supertypes(class_symbol)]
          end

          defs = symbols.flat_map(&:definitions).grep(Model::Namespace).flat_map(&:children).grep(Model::Method)
          defs.select! { |m| m.name == name }

          defs
        when RBI::Type::Simple
          type_symbol = @model.symbols[type.to_rbi]
          raise Error.new("unknown symbol for type #{type.to_rbi}", @method.location) unless type_symbol

          symbols = [type_symbol, *@model.supertypes(type_symbol)]

          defs = symbols.flat_map(&:definitions).grep(Model::Namespace).flat_map(&:children).grep(Model::Method)
          defs.select! { |m| m.name == name }
          # defs.select!(&:singleton?) if singleton_context

          # TODO: linearize results properly
          defs
        when RBI::Type::Nilable
          # TODO: intersection
          resolve_method_for_type(type.type, name)
        else
          raise "unexpected type: #{type}"
        end
      rescue Poset::Error
        nil
      end

      sig { returns(Scope) }
      def current_scope
        T.must(@scope_stack.last)
      end

      sig { params(message: String, node: Prism::Node).returns(Error) }
      def error(message, node)
        location = node_location(node)
        Error.new(message, location)
      end

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@method.location.file, node.location)
      end

      sig { params(method: Model::Method).returns(RBI::Type) }
      def self_type_for(method)
        owner = method.owner

        if owner
          type = RBI::Type.simple(owner.symbol.full_name)
          type = RBI::Type.class_of(type) if method.is_singleton
          type
        else
          RBI::Type.simple("Object")
        end
      end
    end
  end
end
