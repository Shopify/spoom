# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    # Populate a Model by visiting the nodes from a Ruby file
    class Builder < NamespaceVisitor
      #: (Model model, String file) -> void
      def initialize(model, file)
        super()

        @model = model
        @file = file
        @namespace_nesting = [] #: Array[Namespace]
        @visibility_stack = [Visibility::Public] #: Array[Visibility]
        @last_sigs = [] #: Array[Sig]
      end

      # Classes

      # @override
      #: (Prism::ClassNode node) -> void
      def visit_class_node(node)
        @namespace_nesting << Class.new(
          @model.register_symbol(@names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
          superclass_name: node.superclass&.slice,
          comments: node_comments(node),
        )
        @visibility_stack << Visibility::Public
        super
        @visibility_stack.pop
        @namespace_nesting.pop
        @last_sigs.clear
      end

      # @override
      #: (Prism::SingletonClassNode node) -> void
      def visit_singleton_class_node(node)
        @namespace_nesting << SingletonClass.new(
          @model.register_symbol(@names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
          comments: node_comments(node),
        )
        @visibility_stack << Visibility::Public
        super
        @visibility_stack.pop
        @namespace_nesting.pop
        @last_sigs.clear
      end

      # Modules

      # @override
      #: (Prism::ModuleNode node) -> void
      def visit_module_node(node)
        @namespace_nesting << Module.new(
          @model.register_symbol(@names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
          comments: node_comments(node),
        )
        @visibility_stack << Visibility::Public
        super
        @visibility_stack.pop
        @namespace_nesting.pop
        @last_sigs.clear
      end

      # Constants

      # @override
      #: (Prism::ConstantPathWriteNode node) -> void
      def visit_constant_path_write_node(node)
        @last_sigs.clear

        name = node.target.slice
        full_name = if name.start_with?("::")
          name.delete_prefix("::")
        else
          [*@names_nesting, name].join("::")
        end

        Constant.new(
          @model.register_symbol(full_name),
          owner: @namespace_nesting.last,
          location: node_location(node),
          value: node.value.slice,
          comments: node_comments(node),
        )

        super
      end

      # @override
      #: (Prism::ConstantWriteNode node) -> void
      def visit_constant_write_node(node)
        @last_sigs.clear

        Constant.new(
          @model.register_symbol([*@names_nesting, node.name.to_s].join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
          value: node.value.slice,
          comments: node_comments(node),
        )

        super
      end

      # @override
      #: (Prism::MultiWriteNode node) -> void
      def visit_multi_write_node(node)
        @last_sigs.clear

        node.lefts.each do |const|
          case const
          when Prism::ConstantTargetNode, Prism::ConstantPathTargetNode
            Constant.new(
              @model.register_symbol([*@names_nesting, const.slice].join("::")),
              owner: @namespace_nesting.last,
              location: node_location(const),
              value: node.value.slice,
              comments: node_comments(const),
            )
          end
        end

        super
      end

      # Methods

      # @override
      #: (Prism::DefNode node) -> void
      def visit_def_node(node)
        recv = node.receiver

        if !recv || recv.is_a?(Prism::SelfNode)
          Method.new(
            @model.register_symbol([*@names_nesting, node.name.to_s].join("::")),
            owner: @namespace_nesting.last,
            location: node_location(node),
            visibility: current_visibility,
            sigs: collect_sigs,
            comments: node_comments(node),
          )
        end

        super
      end

      # Accessors

      # @override
      #: (Prism::CallNode node) -> void
      def visit_call_node(node)
        return if node.receiver && !node.receiver.is_a?(Prism::SelfNode)

        current_namespace = @namespace_nesting.last

        case node.name
        when :attr_accessor
          sigs = collect_sigs
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            AttrAccessor.new(
              @model.register_symbol([*@names_nesting, arg.slice.delete_prefix(":")].join("::")),
              owner: current_namespace,
              location: node_location(arg),
              visibility: current_visibility,
              sigs: sigs,
              comments: node_comments(node),
            )
          end
        when :attr_reader
          sigs = collect_sigs
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            AttrReader.new(
              @model.register_symbol([*@names_nesting, arg.slice.delete_prefix(":")].join("::")),
              owner: current_namespace,
              location: node_location(arg),
              visibility: current_visibility,
              sigs: sigs,
              comments: node_comments(node),
            )
          end
        when :attr_writer
          sigs = collect_sigs
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            AttrWriter.new(
              @model.register_symbol([*@names_nesting, arg.slice.delete_prefix(":")].join("::")),
              owner: current_namespace,
              location: node_location(arg),
              visibility: current_visibility,
              sigs: sigs,
              comments: node_comments(node),
            )
          end
        when :include
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
            next unless current_namespace

            current_namespace.mixins << Include.new(arg.slice)
          end
        when :prepend
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
            next unless current_namespace

            current_namespace.mixins << Prepend.new(arg.slice)
          end
        when :extend
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
            next unless current_namespace

            current_namespace.mixins << Extend.new(arg.slice)
          end
        when :public, :private, :protected
          @visibility_stack << Visibility.from_serialized(node.name.to_s)
          if node.arguments
            super
            @visibility_stack.pop
          end
        when :sig
          @last_sigs << Sig.new(node.slice)
        else
          @last_sigs.clear
          super
        end
      end

      private

      #: -> Visibility
      def current_visibility
        T.must(@visibility_stack.last)
      end

      #: -> Array[Sig]
      def collect_sigs
        sigs = @last_sigs
        @last_sigs = []
        sigs
      end

      #: (Prism::Node node) -> Location
      def node_location(node)
        Location.from_prism(@file, node.location)
      end

      #: (Prism::Node node) -> Array[Comment]
      def node_comments(node)
        last_line = node.location.start_line
        comments = []

        node.location.leading_comments.reverse_each do |comment|
          if comment.location.start_line < last_line - 1
            break
          end

          last_line = comment.location.start_line

          comments.unshift(Comment.new(
            comment.slice.gsub(/^#\s?/, "").rstrip,
            Location.from_prism(@file, comment.location),
          ))
        end

        comments
      end
    end
  end
end
