# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class Builder < Visitor
      extend T::Sig

      sig { params(model: Model, file: String).void }
      def initialize(model, file)
        @model = model
        @file = file
        @code = T.let(File.read(file), String)
        @ast = T.let(Spoom.parse_file(file), T.nilable(Prism::Node))

        @names_nesting = T.let([], T::Array[String])

        root_scope_def = ClassDef.new(Location.none)
        @scopes_nesting = T.let([root_scope_def], T::Array[ScopeDef])
      end

      sig { void }
      def enter_visit
        visit(@ast)
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        constant_path = node.constant_path.slice
        location = node_location(node)

        if constant_path.start_with?("::")
          full_name = constant_path.delete_prefix("::")

          # We found a top level definition such as `class ::A; end`, we need to reset the name nesting
          old_nesting = @names_nesting.dup
          @names_nesting.clear
          @names_nesting << full_name

          scope_def = ClassDef.new(location)
          @model.register_class_def(full_name, scope_def)
          @scopes_nesting << scope_def

          # We do not call `super` here because we don't want to visit the `constant` again
          visit(node.superclass) if node.superclass
          visit(node.body)

          # Restore the name nesting once we finished visited the class
          @names_nesting.clear
          @names_nesting = old_nesting

          @scopes_nesting.pop
        else
          @names_nesting << constant_path

          scope_def = ClassDef.new(location)
          @model.register_class_def(@names_nesting.join("::"), scope_def)
          @scopes_nesting << scope_def

          # We do not call `super` here because we don't want to visit the `constant` again
          visit(node.superclass) if node.superclass
          visit(node.body)

          @names_nesting.pop
        end
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        constant_path = node.constant_path.slice
        location = node_location(node)

        if constant_path.start_with?("::")
          full_name = constant_path.delete_prefix("::")

          # We found a top level definition such as `class ::A; end`, we need to reset the name nesting
          old_nesting = @names_nesting.dup
          @names_nesting.clear
          @names_nesting << full_name

          scope_def = ModuleDef.new(location)
          @model.register_module_def(full_name, scope_def)
          @scopes_nesting << scope_def

          visit(node.body)

          # Restore the name nesting once we finished visited the class
          @names_nesting.clear
          @names_nesting = old_nesting
        else
          @names_nesting << constant_path

          scope_def = ModuleDef.new(location)
          @model.register_module_def(@names_nesting.join("::"), scope_def)
          @scopes_nesting << scope_def

          # We do not call `super` here because we don't want to visit the `constant` again
          visit(node.body)

          @names_nesting.pop
        end
      end

      sig { override.params(node: Prism::ConstantPathNode).void }
      def visit_constant_path_node(node)
        current_scope_def.constant_refs << Ref.new(node.slice, node_location(node))
      end

      sig { override.params(node: Prism::ConstantReadNode).void }
      def visit_constant_read_node(node)
        current_scope_def.constant_refs << Ref.new(node.name.to_s, node_location(node))
      end

      sig { override.params(node: Prism::ConstantWriteNode).void }
      def visit_constant_write_node(node)
        const_def = ConstantDef.new(node_location(node))
        @model.register_constant_def([*@names_nesting, node.name.to_s].join("::"), const_def)
        visit(node.value)
      end

      private

      sig { returns(ScopeDef) }
      def current_scope_def
        T.must(@scopes_nesting.last)
      end

      sig { params(node: Prism::Node).returns(Location) }
      def node_location(node)
        Location.from_prism(@file, node.location)
      end
    end
  end
end
