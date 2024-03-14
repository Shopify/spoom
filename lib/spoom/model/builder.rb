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
      end

      # Classes

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        full_name = names_nesting.join("::")

        symbol = @model.symbols[full_name]
        raise Error, "#{full_name} previously defined as a #{symbol.class}" if symbol && !symbol.is_a?(Class)

        unless symbol
          symbol = @model.symbols[full_name] = Class.new(full_name)
        end

        symbol.locs << node_location(node)

        superclass_name = node.superclass&.slice
        if superclass_name
          other_superclass = symbol.superclass_name
          if other_superclass && other_superclass.delete_prefix("::") != superclass_name.delete_prefix("::")
            raise Error, "superclass redefined from #{symbol.superclass_name} to #{superclass_name}\n"
            #\
            #  "  previously defined as #{other_superclass} at #{symbol.location}\n" \
            #  "  redefined as #{superclass_name} at #{node_location(node)}"
          end

          symbol.superclass_name = superclass_name
        end

        # @model.register_class_def(names_nesting.join("::"), node_location(node))

        super
      end

      # Modules

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        full_name = names_nesting.join("::")

        symbol = @model.symbols[full_name]
        raise Error, "#{full_name} previously defined as a #{symbol.class}" if symbol && !symbol.is_a?(Module)

        unless symbol
          symbol = @model.symbols[full_name] = Module.new(full_name)
        end

        symbol.locs << node_location(node)

        # @model.register_module_def(names_nesting.join("::"), node_location(node))

        super
      end

      # Constants

      # sig { override.params(node: Prism::ConstantPathWriteNode).void }
      # def visit_constant_path_write_node(node)
      #   location = node_location(node)
      #   name = node.target.slice

      #   if name.start_with?("::")
      #     name = name.delete_prefix("::")

      #     @model.register_constant_def(name, location)
      #   else
      #     @model.register_constant_def(namespace_with(name), location)
      #   end

      #   super
      # end

      # sig { override.params(node: Prism::ConstantWriteNode).void }
      # def visit_constant_write_node(node)
      #   @model.register_constant_def(namespace_with(node.name.to_s), node_location(node))

      #   super
      # end

      # sig { override.params(node: Prism::MultiWriteNode).void }
      # def visit_multi_write_node(node)
      #   node.lefts.each do |const|
      #     case const
      #     when Prism::ConstantTargetNode, Prism::ConstantPathTargetNode
      #       @model.register_constant_def(namespace_with(const.slice), node_location(const))
      #     end
      #   end

      #   super
      # end

      # Methods

      # sig { override.params(node: Prism::DefNode).void }
      # def visit_def_node(node)
      #   @model.register_method_def(namespace_with(node.name.to_s), node_location(node))

      #   super
      # end

      # Accessors

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        return if node.receiver

        case node.name
        when :include, :extend, :prepend
          args = node.arguments&.arguments
          kind = Mixin::Kind.deserialize(node.name.to_s)

          args&.each do |arg|
            next unless arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)

            current_namespace = @model.symbols[names_nesting.join("::")]
            next unless current_namespace.is_a?(Namespace)

            current_namespace.mixins << Mixin.new(kind, arg.slice)
          end
        # when :attr_reader, :attr_writer, :attr_accessor
        #   args = node.arguments&.arguments || []

        #   args.each do |arg|
        #     next unless arg.is_a?(Prism::SymbolNode)

        #     @model.register_accessor_def(namespace_with(arg.unescaped), node_location(arg))
          # end
        end

        super
      end

      # private

      # sig { params(name: String).returns(String) }
      # def namespace_with(name)
      #   [*names_nesting, name].join("::")
      # end

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@file, node.location)
      end
    end
  end
end
