# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class Builder < NamespaceVisitor
      extend T::Sig

      sig { params(model: Model, file: String).void }
      def initialize(model, file)
        super()

        @model = model
        @file = file
        @namespace_nesting = T.let([], T::Array[Namespace])
        @last_sigs = T.let([], T::Array[Sig])
      end

      # Classes

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        @namespace_nesting << Class.new(
          @model.register_symbol(names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
          superclass_name: node.superclass&.slice,
        )
        super
        @namespace_nesting.pop
        @last_sigs.clear
      end

      sig { override.params(node: Prism::SingletonClassNode).void }
      def visit_singleton_class_node(node)
        @namespace_nesting << SingletonClass.new(
          @model.register_symbol(names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
        )
        super
        @namespace_nesting.pop
        @last_sigs.clear
      end

      # Modules

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        @namespace_nesting << Module.new(
          @model.register_symbol(names_nesting.join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
        )
        super
        @namespace_nesting.pop
        @last_sigs.clear
      end

      # Constants

      sig { override.params(node: Prism::ConstantPathWriteNode).void }
      def visit_constant_path_write_node(node)
        @last_sigs.clear

        name = node.target.slice
        full_name = if name.start_with?("::")
          name.delete_prefix("::")
        else
          [*names_nesting, name].join("::")
        end

        Constant.new(
          @model.register_symbol(full_name),
          owner: @namespace_nesting.last,
          location: node_location(node),
        )

        super
      end

      sig { override.params(node: Prism::ConstantWriteNode).void }
      def visit_constant_write_node(node)
        @last_sigs.clear

        Constant.new(
          @model.register_symbol([*names_nesting, node.name.to_s].join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
        )

        super
      end

      sig { override.params(node: Prism::MultiWriteNode).void }
      def visit_multi_write_node(node)
        @last_sigs.clear

        node.lefts.each do |const|
          case const
          when Prism::ConstantTargetNode, Prism::ConstantPathTargetNode
            Constant.new(
              @model.register_symbol([*names_nesting, const.slice].join("::")),
              owner: @namespace_nesting.last,
              location: node_location(const),
            )
          end
        end

        super
      end

      # Methods

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        Method.new(
          @model.register_symbol([*names_nesting, node.name.to_s].join("::")),
          owner: @namespace_nesting.last,
          location: node_location(node),
          sigs: collect_sigs,
        )

        super
      end

      # Accessors

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        return if node.receiver

        case node.name
        when :attr_accessor
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            AttrAccessor.new(
              @model.register_symbol([*names_nesting, arg.slice.delete_prefix(":")].join("::")),
              owner: @namespace_nesting.last,
              location: node_location(arg),
              sigs: collect_sigs,
            )
          end
        when :attr_reader
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            AttrReader.new(
              @model.register_symbol([*names_nesting, arg.slice.delete_prefix(":")].join("::")),
              owner: @namespace_nesting.last,
              location: node_location(arg),
              sigs: collect_sigs,
            )
          end
        when :attr_writer
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            AttrWriter.new(
              @model.register_symbol([*names_nesting, "#{arg.slice.delete_prefix(":")}="].join("::")),
              owner: @namespace_nesting.last,
              location: node_location(arg),
              sigs: collect_sigs,
            )
          end
        when :include, :extend, :prepend
          args = node.arguments&.arguments
          kind = Mixin::Kind.deserialize(node.name.to_s)

          args&.each do |arg|
            next unless arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)

            current_namespace = @namespace_nesting.last
            next unless current_namespace

            current_namespace.mixins << Mixin.new(kind, arg.slice)
          end
        when :sig
          @last_sigs << Sig.new(node.slice)
        else
          @last_sigs.clear
          super
        end
      end

      private

      sig { returns(T::Array[Sig]) }
      def collect_sigs
        sigs = @last_sigs
        @last_sigs = []
        sigs
      end

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@file, node.location)
      end
    end
  end
end
