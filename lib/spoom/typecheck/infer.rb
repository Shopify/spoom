# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    # Equivalent to infer - 7000 phase in Sorbet
    class Infer < Visitor
      extend T::Sig

      class Result < T::Struct
        prop :errors, T::Array[Error], default: []
      end

      class << self
        extend T::Sig

        sig { params(model: Model, parsed_files: T::Array[[String, Prism::Node]]).returns(Result) }
        def run(model, parsed_files)
          result = Result.new

          parsed_files.each do |file, node|
            infer = Spoom::Typecheck::Infer.new(model, file)
            infer.visit(node)
            result.errors.concat(infer.errors)
          end

          result
        end
      end

      class Scope
        extend T::Sig

        sig { returns(RBI::Type) }
        attr_reader :self_type

        sig { returns(T::Hash[String, RBI::Type]) }
        attr_reader :var_types

        sig { params(self_type: RBI::Type).void }
        def initialize(self_type)
          @self_type = self_type
          @var_types = T.let({}, T::Hash[String, RBI::Type])
        end

        sig { params(self_type: RBI::Type).returns(Scope) }
        def new(self_type)
          scope = Scope.new(self_type)
          scope.var_types.merge!(var_types)
          scope
        end

        sig { params(name: String).returns(T::Boolean) }
        def var?(name)
          var_types.key?(name)
        end

        sig { returns(Scope) }
        def dup
          Scope.new(@self_type).tap do |scope|
            scope.var_types.merge!(var_types)
          end
        end
      end

      sig { returns(T::Array[Error]) }
      attr_reader :errors

      sig { params(model: Model, file: String).void }
      def initialize(model, file)
        super()

        @model = model
        @file = file
        @errors = T.let([], T::Array[Error])
        @scope_stack = T.let([Scope.new(RBI::Type.simple("Object"))], T::Array[Scope])
      end

      # Nodes

      sig { override.params(node: Prism::AndNode).void }
      def visit_and_node(node)
        @scope_stack << current_scope.dup
        visit(node.left)
        visit(node.right)
        @scope_stack.pop

        node.spoom_type = RBI::Type.simple("T::Boolean")
      end

      sig { override.params(node: Prism::ArrayNode).void }
      def visit_array_node(node)
        super

        node.spoom_type = RBI::Type.simple("Array")
      end

      sig { override.params(node: Prism::BlockNode).void }
      def visit_block_node(node)
        @scope_stack << current_scope.dup
        super
        @scope_stack.pop

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
        return if node.name == :sig

        receiver = node.receiver
        receiver_name = receiver&.slice
        receiver_type = if receiver
          visit(receiver)
          type = receiver.spoom_type

          unless type
            @errors << error("Missing type for `#{receiver.slice}` (#{receiver.class})", receiver)
            type = RBI::Type.untyped
          end

          if type.is_a?(RBI::Type::Nilable) && node.call_operator == "&."
            type = type.type
          end

          type
        else
          current_scope.self_type
        end

        # if receiver_type.is_a?(RBI::Type::Untyped)
        #   @errors << error("untyped receiver", node)
        # end

        visit(node.arguments)

        if receiver_name && node.name == :is_a? && current_scope.var?(receiver_name)
          if node.arguments&.arguments&.size == 1 &&
              (
                node.arguments&.child_nodes&.first&.is_a?(Prism::ConstantPathNode) ||
                node.arguments&.child_nodes&.first&.is_a?(Prism::ConstantReadNode)
              ) &&
              (const = T.cast(
                node.arguments&.child_nodes&.first,
                T.any(Prism::ConstantPathNode, Prism::ConstantReadNode),
              ))
            current_scope.var_types[receiver_name] = T.cast(const.spoom_type, RBI::Type::ClassOf).type
          end
        end

        visit(node.block)

        method_symbols = resolve_method_for_type(node, receiver_type, node.name.to_s) || []

        if method_symbols.empty?
          node.spoom_type = RBI::Type.untyped
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
        predicate = node.predicate
        local = current_scope.var_types[predicate.slice] if predicate

        node.conditions.each do |when_node|
          raise unless when_node.is_a?(Prism::WhenNode)

          @scope_stack << current_scope.dup

          when_node.conditions.each do |cond|
            case cond
            when Prism::ConstantReadNode, Prism::ConstantPathNode
              symbol = cond.spoom_symbol
              raise unless symbol

              current_scope.var_types[predicate.slice] = RBI::Type.simple(symbol.full_name) if predicate && local
            end

            visit(cond)
          end
          @scope_stack.pop
        end

        # TODO
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        symbol = node.spoom_symbol_def
        raise unless symbol.is_a?(Model::Class)

        @scope_stack << current_scope.new(RBI::Type.class_of(
          RBI::Type.simple(symbol.full_name),
        ))
        super
        @scope_stack.pop

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
        method = node.spoom_symbol_def
        raise unless method.is_a?(Model::Method)

        # TODO: handle multiple sigs
        sig = method.symbol.definitions.grep(Model::Method).flat_map(&:sigs).first

        @scope_stack << current_scope.new(self_type_for(method))
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
              current_scope.var_types[param.name.to_s] = type
            end
          end
        end
        super
        @scope_stack.pop

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
        if_scope = current_scope.dup
        else_scope = current_scope.dup

        @scope_stack << if_scope
        visit(node.predicate)
        visit(node.statements)
        @scope_stack.pop

        if node.consequent
          @scope_stack << else_scope
          visit(node.consequent)
          @scope_stack.pop
        end

        # TODO: merge type
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::InstanceVariableReadNode).void }
      def visit_instance_variable_read_node(node)
        node.spoom_type = RBI::Type.untyped
      end

      sig { override.params(node: Prism::IntegerNode).void }
      def visit_integer_node(node)
        node.spoom_type = RBI::Type.simple("Integer")
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
          @errors << error("Missing type for local variable `#{node.name}`", node)
          type = RBI::Type.untyped
        end

        node.spoom_type = type
      end

      sig { override.params(node: Prism::LocalVariableWriteNode).void }
      def visit_local_variable_write_node(node)
        super

        type = node.value.spoom_type
        unless type
          @errors << error("Missing type for `#{node.value.slice}` (#{node.value.class})", node.value)
          type = RBI::Type.untyped
        end

        current_scope.var_types[node.name.to_s] = type
        node.spoom_type = type
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        symbol = node.spoom_symbol_def
        raise unless symbol.is_a?(Model::Module)

        @scope_stack << current_scope.new(RBI::Type.class_of(
          RBI::Type.simple(symbol.full_name),
        ))
        super
        @scope_stack.pop

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
            raise "Not yet impl #{left.class}"
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
          @errors << error("Missing type for `#{node.value.slice}` (#{node.value.class})", node.value)
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
        node.spoom_type = current_scope.self_type
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
          raise "Unexpected `attached_class`" unless recv_type.is_a?(RBI::Type::ClassOf)

          return_type = recv_type.type
        end
        sig.return_type = return_type
        sig
      end

      sig do
        params(
          node: Prism::CallNode,
          type: RBI::Type,
          name: String,
        ).returns(T.nilable(T::Array[T.any(Model::Method, Model::Attr)]))
      end
      def resolve_method_for_type(node, type, name)
        # puts "resolve_method_for_type: #{type} (#{type.class}) #{name}"
        case type
        when RBI::Type.untyped
          nil
        when RBI::Type::Simple
          # puts "simple: #{type}"
          type_symbol = @model.symbols[type.to_rbi]
          unless type_symbol
            # puts "error"
            @errors << error("Unknown symbol for type #{type.to_rbi}", node)
            return []
          end

          defs = @model.resolve_method(type_symbol, name, singleton: false)

          if defs.empty? && !IGNORED_METHODS.include?(name)
            @errors << Error.new(
              "Method `#{name}` does not exist on `#{type_symbol}`",
              Location.from_prism(@file, T.must(node.message_loc)),
            )
          end

          defs
        when RBI::Type::ClassOf, RBI::Type::Class
          inner_type = type.type
          return if inner_type.is_a?(RBI::Type::Untyped)

          type_symbol = @model.symbols[inner_type.to_rbi]
          unless type_symbol
            @errors << error("Unknown symbol for type #{inner_type.to_rbi}", node)
            return []
          end

          defs = @model.resolve_method(type_symbol, name, singleton: true)

          if defs.empty? && !IGNORED_METHODS.include?(name)
            @errors << Error.new(
              "Method `#{name}` does not exist on `T.class_of(#{type_symbol})`",
              Location.from_prism(@file, T.must(node.message_loc)),
            )
          end

          defs
        when RBI::Type::Generic
          # TODO
          case type.name
          when "T::Array"
            resolve_method_for_type(node, RBI::Type.simple("Array"), name)
          when "T::Hash"
            resolve_method_for_type(node, RBI::Type.simple("Hash"), name)
          end
        when RBI::Type::Boolean
          resolve_method_for_type(
            node,
            RBI::Type::Any.new([
              RBI::Type.simple("TrueClass"),
              RBI::Type.simple("FalseClass"),
            ]),
            name,
          )
        when RBI::Type::Nilable
          resolve_method_for_type(
            node,
            RBI::Type::Any.new([
              type.type,
              RBI::Type.simple("NilClass"),
            ]),
            name,
          )
        when RBI::Type::All
          type.types.map { |t| resolve_method_for_type(node, t, name) }.flatten.compact
        when RBI::Type::Any
          type.types.map { |t| resolve_method_for_type(node, t, name) }.reduce(:&)
        when RBI::Type::TypeParameter, RBI::Type::Proc
          # TODO
          @errors << error("Not yet implemented `#{type}` (#{type.class})", node)
          nil
        when RBI::Type::Void
          []
        else
          @errors << error("Unexpected type `#{type}` (#{type.class})", node)
          raise "Unexpected type: #{type} (#{type.class})"
          # return
        end
      rescue Poset::Error => e
        @errors << error("POSet error in type resolution `#{type}` (#{type.class})", node)
        nil
      end

      IGNORED_METHODS = T.let(
        Set.new([
          "_",
        ]),
        T::Set[String],
      )

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
        Location.from_prism(@file, node.location)
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
