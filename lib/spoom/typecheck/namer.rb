# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    class Namer < Spoom::Model::NamespaceVisitor
      extend T::Sig

      class Error < Typecheck::Error; end

      sig { params(model: Model, file: String).void }
      def initialize(model, file)
        super()

        @model = model
        @file = file
        @namespace_nesting = T.let([], T::Array[Model::Namespace])
        @visibility_stack = T.let([Model::Visibility::Public], T::Array[Model::Visibility])
        @last_sigs = T.let([], T::Array[Model::Sig])
      end

      # Classes

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        symbol_def = Model::Class.new(
          @model.register_symbol(@names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
          superclass_name: node.superclass&.slice,
        )

        node.spoom_symbol_def = symbol_def

        @namespace_nesting << symbol_def
        @visibility_stack << Model::Visibility::Public
        super
        @visibility_stack.pop
        @namespace_nesting.pop
        @last_sigs.clear
      end

      sig { override.params(node: Prism::SingletonClassNode).void }
      def visit_singleton_class_node(node)
        @namespace_nesting << Model::SingletonClass.new(
          @model.register_symbol(@names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
        )

        @visibility_stack << Model::Visibility::Public
        super
        @visibility_stack.pop
        @namespace_nesting.pop
        @last_sigs.clear
      end

      # Modules

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        symbol_def = Model::Module.new(
          @model.register_symbol(@names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
        )

        node.spoom_symbol_def = symbol_def

        @namespace_nesting << symbol_def
        @visibility_stack << Model::Visibility::Public
        super
        @visibility_stack.pop
        @namespace_nesting.pop
        @last_sigs.clear
      end

      # Constants

      sig { override.params(node: Prism::ConstantPathNode).void }
      def visit_constant_path_node(node)
        visit(node.parent)
        node.spoom_symbol = Model::UnresolvedRef.new(node.slice, context: @namespace_nesting.last)

        super
      end

      sig { override.params(node: Prism::ConstantReadNode).void }
      def visit_constant_read_node(node)
        node.spoom_symbol = Model::UnresolvedRef.new(node.slice, context: @namespace_nesting.last)

        super
      end

      sig { override.params(node: Prism::ConstantPathWriteNode).void }
      def visit_constant_path_write_node(node)
        @last_sigs.clear

        name = node.target.slice
        full_name = if name.start_with?("::")
          name.delete_prefix("::")
        else
          [*@names_nesting, name].join("::")
        end

        symbol_def = Model::Constant.new(
          @model.register_symbol(full_name),
          owner: @namespace_nesting.last,
          location: node_location(node),
          value: node.value.slice,
        )

        node.spoom_symbol_def = symbol_def

        super
      end

      sig { override.params(node: Prism::ConstantWriteNode).void }
      def visit_constant_write_node(node)
        # @last_sigs.clear

        symbol_def = if node.value.is_a?(Prism::ConstantReadNode) || node.value.is_a?(Prism::ConstantPathNode)
          constant_alias = Model::Alias.new(
            @model.register_symbol([*@names_nesting, node.name.to_s].join("::")),
            owner: @namespace_nesting.last,
            location: node_location(node),
            value: node.value.slice,
            target: Model::UnresolvedRef.new(node.value.slice, context: @namespace_nesting.last),
          )

          constant_alias
        else
          Model::Constant.new(
            @model.register_symbol([*@names_nesting, node.name.to_s].join("::")),
            owner: @namespace_nesting.last,
            location: node_location(node),
            value: node.value.slice,
          )
        end

        node.spoom_symbol_def = symbol_def

        super
      end

      sig { override.params(node: Prism::MultiWriteNode).void }
      def visit_multi_write_node(node)
        # @last_sigs.clear

        node.lefts.each do |const|
          case const
          when Prism::ConstantTargetNode, Prism::ConstantPathTargetNode
            Model::Constant.new(
              @model.register_symbol([*@names_nesting, const.slice].join("::")),
              owner: @namespace_nesting.last,
              location: node_location(const),
              value: node.value.slice,
            )
          end
        end

        super
      end

      # Methods

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        recv = node.receiver

        if !recv || recv.is_a?(Prism::SelfNode)
          symbol_def = Model::Method.new(
            @model.register_symbol([*@names_nesting, node.name.to_s].join("::")),
            owner: @namespace_nesting.last,
            location: node_location(node),
            visibility: current_visibility,
            sigs: collect_sigs,
          )

          node.spoom_symbol_def = symbol_def
        end

        super
      end

      # Accessors

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        if node.receiver && !node.receiver.is_a?(Prism::SelfNode)
          super
          return
        end

        current_namespace = @namespace_nesting.last

        case node.name
        when :attr_accessor
          sigs = collect_sigs
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            Model::AttrAccessor.new(
              @model.register_symbol([*@names_nesting, arg.slice.delete_prefix(":")].join("::")),
              owner: current_namespace,
              location: node_location(arg),
              visibility: current_visibility,
              sigs: sigs,
            )
          end
        when :attr_reader
          sigs = collect_sigs
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            Model::AttrReader.new(
              @model.register_symbol([*@names_nesting, arg.slice.delete_prefix(":")].join("::")),
              owner: current_namespace,
              location: node_location(arg),
              visibility: current_visibility,
              sigs: sigs,
            )
          end
        when :attr_writer
          sigs = collect_sigs
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            Model::AttrWriter.new(
              @model.register_symbol([*@names_nesting, arg.slice.delete_prefix(":")].join("::")),
              owner: current_namespace,
              location: node_location(arg),
              visibility: current_visibility,
              sigs: sigs,
            )
          end
        when :include
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
            next unless current_namespace

            current_namespace.mixins << Model::Include.new(arg.slice)
            super
          end
        when :prepend
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
            next unless current_namespace

            current_namespace.mixins << Model::Prepend.new(arg.slice)
            super
          end
        when :extend
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
            next unless current_namespace

            current_namespace.mixins << Model::Extend.new(arg.slice)
            super
          end
        when :public, :private, :protected
          @visibility_stack << Model::Visibility.from_serialized(node.name.to_s)
          if node.arguments
            super
            @visibility_stack.pop
          end
        when :sig
          @last_sigs << Model::Sig.new(node.slice)
          super
        else
          super
        end
      end

      private

      sig { returns(Model::Visibility) }
      def current_visibility
        T.must(@visibility_stack.last)
      end

      sig { returns(T::Array[Model::Sig]) }
      def collect_sigs
        sigs = @last_sigs
        @last_sigs = []
        sigs
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
