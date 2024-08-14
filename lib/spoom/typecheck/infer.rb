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
        sig = method.symbol.definitions.grep(Model::Method).flat_map(&:sigs).first

        scope = Scope.new
        if node.is_a?(Prism::DefNode)
          node.parameters&.child_nodes&.compact&.each do |param|
            case param
            when Prism::RequiredParameterNode, Prism::OptionalParameterNode, Prism::RestParameterNode,
                Prism::RequiredKeywordParameterNode, Prism::OptionalKeywordParameterNode, Prism::KeywordRestParameterNode,
                Prism::BlockParameterNode
              type = if sig
                sig.params.find { |p| p.name == param.name.to_s }&.type || RBI::Type.untyped
              else
                RBI::Type.untyped
              end
              param.spoom_type = type
              scope.var_types[param.name.to_s] = type
            end
          end
        end

        @scope_stack = T.let([scope], T::Array[Scope])

        @seen = T.let(Set.new, T::Set[Spoom::CFG::BasicBlock])
      end

      # CFG

      sig { void }
      def infer
        # visit(@node)
        visit_cfg(@cfg)
      end

      sig { params(cfg: Spoom::CFG).void }
      def visit_cfg(cfg)
        visit_basic_block(cfg.root)
      end

      sig { params(block: Spoom::CFG::BasicBlock).void }
      def visit_basic_block(block)
        return if @seen.include?(block)

        @seen << block

        block.instructions.each do |instr|
          visit(instr)
        end

        block.outs.each do |succ|
          visit_basic_block(succ)
        end
      end

      # Nodes

      def visit(node)
        return unless node

        # puts node.class
        super
      end

      sig { override.params(node: Prism::ArrayNode).void }
      def visit_array_node(node)
        super

        node.spoom_type = RBI::Type.simple("Array")
      end

      sig { override.params(node: Prism::BlockNode).void }
      def visit_block_node(node)
        super

        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::BlockParametersNode).void }
      def visit_block_parameters_node(node)
        # TODO: type blocks
        node.parameters&.child_nodes&.each do |param|
          case param
          when Prism::RequiredParameterNode, Prism::OptionalParameterNode, Prism::RestParameterNode,
              Prism::RequiredKeywordParameterNode, Prism::OptionalKeywordParameterNode, Prism::KeywordRestParameterNode,
              Prism::BlockParameterNode
            type = RBI::Type.untyped
            param.spoom_type = type
            current_scope.var_types[param.name.to_s] = type
          end
        end
        # TODO: locals
      end

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        receiver = node.receiver

        receiver_type = if receiver
          visit(receiver)
          type = receiver.spoom_type

          unless type
            @errors << error("missing type for `#{receiver.slice}` (#{receiver.class})", receiver)
            type = RBI::Type.untyped
          end

          type
        else
          @self_type
        end

        # if receiver_type.is_a?(RBI::Type::Untyped)
        #   @errors << error("untyped receiver", node)
        # end

        visit(node.arguments)
        visit(node.block)

        method_symbols = resolve_method_for_type(receiver_type, node.name.to_s) || []
        if method_symbols.empty? && !receiver_type.is_a?(RBI::Type::Untyped)
          @errors << error("missing method `#{node.name}` for type `#{receiver_type}`", node)
        end
        node.spoom_method_symbol = method_symbols.first

        sigs = method_symbols.flat_map(&:sigs)
        # TODO: support multiple sigs
        sig = sigs.first

        node.spoom_type = if sig
          sig = resolve_signature(receiver_type, sig)
          sig.return_type
        else
          RBI::Type.untyped
        end
      end

      sig { override.params(node: Prism::CaseNode).void }
      def visit_case_node(node)
        super

        # TODO
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        super

        node.spoom_type = RBI::Type.simple("NilClass")
      end

      sig { override.params(node: Prism::ConstantPathNode).void }
      def visit_constant_path_node(node)
        symbol = node.spoom_symbol
        raise error("missing resolved symbol", node) unless symbol

        node.spoom_type = RBI::Type.class_of(RBI::Type.simple(symbol.full_name))
      end

      sig { override.params(node: Prism::ConstantReadNode).void }
      def visit_constant_read_node(node)
        symbol = node.spoom_symbol
        raise error("missing resolved symbol", node) unless symbol

        node.spoom_type = RBI::Type.class_of(RBI::Type.simple(symbol.full_name))
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        # no super

        node.spoom_type = RBI::Type.simple("Symbol")
      end

      sig { override.params(node: Prism::FalseNode).void }
      def visit_false_node(node)
        node.spoom_type = RBI::Type.simple("FalseClass")
      end

      sig { override.params(node: Prism::GlobalVariableReadNode).void }
      def visit_global_variable_read_node(node)
        # TODO
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::HashNode).void }
      def visit_hash_node(node)
        super

        node.spoom_type = RBI::Type.simple("Hash")
      end

      sig { override.params(node: Prism::IfNode).void }
      def visit_if_node(node)
        super

        # TODO: merge type
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::InstanceVariableReadNode).void }
      def visit_instance_variable_read_node(node)
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::IntegerNode).void }
      def visit_integer_node(node)
        node.spoom_type = RBI::Type.class_of(
          RBI::Type.simple("Integer"),
        )
      end

      sig { override.params(node: Prism::InterpolatedStringNode).void }
      def visit_interpolated_string_node(node)
        node.spoom_type = RBI::Type.simple("String")
      end

      sig { override.params(node: Prism::LocalVariableReadNode).void }
      def visit_local_variable_read_node(node)
        super

        type = current_scope.var_types[node.name.to_s]

        unless type
          @errors << error("missing type for local variable `#{node.name}`", node)
          type = RBI::Type.untyped
        end

        node.spoom_type = type
      end

      sig { override.params(node: Prism::LocalVariableWriteNode).void }
      def visit_local_variable_write_node(node)
        super

        type = node.value.spoom_type
        unless type
          @errors << error("missing type for `#{node.value.slice}` (#{node.value.class})", node.value)
          type = RBI::Type.untyped
        end

        current_scope.var_types[node.name.to_s] = type
        node.spoom_type = type
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        super

        node.spoom_type = RBI::Type.simple("NilClass")
      end

      sig { override.params(node: Prism::MultiWriteNode).void }
      def visit_multi_write_node(node)
        super

        node.lefts.each do |left|
          case left
          when Prism::LocalVariableTargetNode
            # TODO
            type = RBI::Type.untyped
            left.spoom_type = type
            current_scope.var_types[left.name.to_s] = type
          else
            raise "not yet impl #{left.class}"
          end
        end

        rest = node.rest
        if rest.is_a?(Prism::SplatNode)
          type = RBI::Type.untyped
          node.spoom_type = type
          current_scope.var_types[T.must(rest.expression&.slice)] = type
        end

        value_type = node.value.spoom_type

        unless value_type
          @errors << error("missing type for `#{node.value.slice}` (#{node.value.class})", node.value)
          value_type = RBI::Type.untyped
        end

        node.spoom_type = value_type
      end

      sig { override.params(node: Prism::OrNode).void }
      def visit_or_node(node)
        super

        # TODO
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::SelfNode).void }
      def visit_self_node(node)
        node.spoom_type = @self_type
      end

      sig { override.params(node: Prism::StringNode).void }
      def visit_string_node(node)
        node.spoom_type = RBI::Type.simple("String")
      end

      sig { override.params(node: Prism::SuperNode).void }
      def visit_super_node(node)
        # TODO: resolve super method
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::TrueNode).void }
      def visit_true_node(node)
        node.spoom_type = RBI::Type.simple("TrueClass")
      end

      private

      sig { params(recv_type: RBI::Type, sig: RBI::Sig).returns(RBI::Sig) }
      def resolve_signature(recv_type, sig)
        sig = sig.dup
        return_type = sig.return_type

        if return_type == RBI::Type.self_type
          return_type = recv_type
        end
        if return_type == RBI::Type.attached_class
          raise "unexpected attached_class" unless recv_type.is_a?(RBI::Type::ClassOf)

          return_type = recv_type.type
        end
        sig.return_type = return_type
        sig
      end

      sig { params(type: RBI::Type, name: String).returns(T.nilable(T::Array[Model::Method])) }
      def resolve_method_for_type(type, name)
        # puts "resolve_method_for_type: #{type} (#{type.class}) #{name}"
        res = case type
        when RBI::Type.untyped
          []
        when RBI::Type::ClassOf, RBI::Type::Class
          inner_type = type.type
          type_symbol = @model.symbols[inner_type.to_rbi]
          return unless type_symbol

          # raise "unknown symbol for type #{inner_type.to_rbi}" unless type_symbol

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
          # puts "  type: #{type.to_rbi}"
          type_symbol = @model.symbols[type.to_rbi]
          # puts "  type_symbol: #{type_symbol}"
          return unless type_symbol

          # raise Error.new("unknown symbol for type #{type.to_rbi}", @method.location) unless type_symbol

          symbols = [type_symbol, *@model.supertypes(type_symbol)]

          defs = symbols.flat_map(&:definitions).grep(Model::Namespace).flat_map(&:children).grep(Model::Method)
          defs.select! { |m| m.name == name }
          # defs.select!(&:singleton?) if singleton_context

          # TODO: linearize results properly
          defs
        when RBI::Type::Generic
          case type.name
          when "T::Array"
            resolve_method_for_type(RBI::Type.simple("Array"), name)
          when "T::Hash"
            resolve_method_for_type(RBI::Type.simple("Hash"), name)
          else
            # TODO
            []
          end
        when RBI::Type::Nilable, RBI::Type::All, RBI::Type::Any, RBI::Type::Boolean, RBI::Type::TypeParameter
          # candidates = type.types.map { |t| resolve_method_for_type(t, name) }
          # return [] if candidates.any? { |c| c.nil? || c.empty? }

          # candidates.flatten.compact
          []
        when RBI::Type::Boolean
          []
        else
          raise "unexpected type: #{type} (#{type.class})"
        end
        # puts "  ---> #{res&.first}"
        res
      rescue Poset::Error
        puts "  ---> ERROR"
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
