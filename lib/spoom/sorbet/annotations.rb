# typed: strict
# frozen_string_literal: true

require "rbi"

module Spoom
  module Sorbet
    class Annotations
      class << self
        extend T::Sig

        #: (String, file: String) -> String
        def rbi_to_rbs(ruby_contents, file:)
          ruby_contents = ruby_contents.dup
          assigns = collect_assigns(ruby_contents, file: file)

          assigns.reverse.each do |assign|
            start_offset = assign.location.start_offset
            end_offset = start_offset + assign.location.length
            ruby_contents[start_offset...end_offset] = assign.to_rbs
          end

          ruby_contents
        end

        private

        #: (String, file: String) -> Array[AssignNode]
        def collect_assigns(ruby_contents, file:)
          node = Spoom.parse_ruby(ruby_contents, file: file)
          visitor = Locator.new
          visitor.visit(node)
          visitor.assigns
        end
      end

      class AssignNode
        extend T::Sig

        #: Prism::Location
        attr_reader :location

        #: String
        attr_reader :name

        #: String
        attr_reader :operator

        #: Prism::Node
        attr_reader :value

        #: Prism::Node
        attr_reader :type

        #: (Prism::Location, String, String, Prism::Node, Prism::Node) -> void
        def initialize(location, name, operator, value, type)
          @location = location
          @name = name
          @operator = operator
          @value = value
          @type = type
        end

        #: -> String
        def to_rbs
          type = RBI::Type.parse_node(self.type)
          "#{name} #{operator} #{value_to_string} \#: #{type.rbs_string}" # rubocop:disable Style/RedundantStringEscape
        end

        private

        #: -> String
        def value_to_string
          if value.location.start_line == location.start_line
            # The value is on the same line as the assign, so we can just return the slice as is:
            # ```rb
            # a = T.let(nil, T.nilable(String))
            # ```
            # becomes
            # ```rb
            # a = nil #: String?
            # ```
            return value.slice
          end

          # The value is on a different line, so we need to dedent it:
          # ```rb
          # a = T.let(
          #   [
          #     1, 2, 3,
          #   ],
          #   T::Array[Integer],
          # )
          # ```
          # becomes
          # ```rb
          # a = [
          #   1, 2, 3,
          # ] #: Array[Integer]
          # ```
          indent = value.location.start_line - location.start_line
          lines = value.slice.lines
          if lines.size > 1
            lines[1..]&.each_with_index do |line, i|
              lines[i + 1] = line.delete_prefix("  " * indent)
            end
          end
          lines.join
        end
      end

      class Locator < Spoom::Visitor
        extend T::Sig

        ANNOTATION_METHODS = T.let([:let], T::Array[Symbol])

        #: Array[AssignNode]
        attr_reader :assigns

        #: -> void
        def initialize
          super
          @assigns = T.let([], T::Array[AssignNode])
        end

        # Class variables

        # @override
        #: (Prism::ClassVariableAndWriteNode node) -> void
        def visit_class_variable_and_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ClassVariableOperatorWriteNode node) -> void
        def visit_class_variable_operator_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ClassVariableOrWriteNode node) -> void
        def visit_class_variable_or_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ClassVariableWriteNode node) -> void
        def visit_class_variable_write_node(node)
          visit_assign(node)

          super
        end

        # Constants

        # @override
        #: (Prism::ConstantAndWriteNode node) -> void
        def visit_constant_and_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ConstantOperatorWriteNode node) -> void
        def visit_constant_operator_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ConstantOrWriteNode node) -> void
        def visit_constant_or_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ConstantWriteNode node) -> void
        def visit_constant_write_node(node)
          visit_assign(node)

          super
        end

        # Constant paths

        # @override
        #: (Prism::ConstantPathAndWriteNode node) -> void
        def visit_constant_path_and_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ConstantPathOperatorWriteNode node) -> void
        def visit_constant_path_operator_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ConstantPathOrWriteNode node) -> void
        def visit_constant_path_or_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::ConstantPathWriteNode node) -> void
        def visit_constant_path_write_node(node)
          visit_assign(node)

          super
        end

        # Global variables

        # @override
        #: (Prism::GlobalVariableAndWriteNode node) -> void
        def visit_global_variable_and_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::GlobalVariableOperatorWriteNode node) -> void
        def visit_global_variable_operator_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::GlobalVariableOrWriteNode node) -> void
        def visit_global_variable_or_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::GlobalVariableWriteNode node) -> void
        def visit_global_variable_write_node(node)
          visit_assign(node)

          super
        end

        # Instance variables

        # @override
        #: (Prism::InstanceVariableAndWriteNode node) -> void
        def visit_instance_variable_and_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::InstanceVariableOperatorWriteNode node) -> void
        def visit_instance_variable_operator_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::InstanceVariableOrWriteNode node) -> void
        def visit_instance_variable_or_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::InstanceVariableWriteNode node) -> void
        def visit_instance_variable_write_node(node)
          visit_assign(node)

          super
        end

        # Local variables

        # @override
        #: (Prism::LocalVariableAndWriteNode node) -> void
        def visit_local_variable_and_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::LocalVariableOperatorWriteNode node) -> void
        def visit_local_variable_operator_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::LocalVariableOrWriteNode node) -> void
        def visit_local_variable_or_write_node(node)
          visit_assign(node)

          super
        end

        # @override
        #: (Prism::LocalVariableWriteNode node) -> void
        def visit_local_variable_write_node(node)
          visit_assign(node)

          super
        end

        private

        AssignType = T.type_alias do
          T.any(
            Prism::ClassVariableAndWriteNode,
            Prism::ClassVariableOrWriteNode,
            Prism::ClassVariableOperatorWriteNode,
            Prism::ClassVariableWriteNode,
            Prism::ConstantAndWriteNode,
            Prism::ConstantOrWriteNode,
            Prism::ConstantOperatorWriteNode,
            Prism::ConstantWriteNode,
            Prism::ConstantPathAndWriteNode,
            Prism::ConstantPathOrWriteNode,
            Prism::ConstantPathOperatorWriteNode,
            Prism::ConstantPathWriteNode,
            Prism::GlobalVariableAndWriteNode,
            Prism::GlobalVariableOrWriteNode,
            Prism::GlobalVariableOperatorWriteNode,
            Prism::GlobalVariableWriteNode,
            Prism::InstanceVariableAndWriteNode,
            Prism::InstanceVariableOperatorWriteNode,
            Prism::InstanceVariableOrWriteNode,
            Prism::InstanceVariableWriteNode,
            Prism::LocalVariableAndWriteNode,
            Prism::LocalVariableOperatorWriteNode,
            Prism::LocalVariableOrWriteNode,
            Prism::LocalVariableWriteNode,
          )
        end

        #: (AssignType) -> void
        def visit_assign(node)
          call = node.value
          if call.is_a?(Prism::CallNode) && t_annotation?(call)
            name = case node
            when Prism::ConstantPathAndWriteNode,
                 Prism::ConstantPathOrWriteNode,
                 Prism::ConstantPathOperatorWriteNode,
                 Prism::ConstantPathWriteNode
              node.target.slice
            else
              node.name.to_s
            end

            operator = case node
            when Prism::ClassVariableAndWriteNode,
                 Prism::ConstantAndWriteNode,
                 Prism::ConstantPathAndWriteNode,
                 Prism::GlobalVariableAndWriteNode,
                 Prism::InstanceVariableAndWriteNode,
                 Prism::LocalVariableAndWriteNode
              "&&="
            when Prism::ClassVariableOrWriteNode,
                 Prism::ConstantOrWriteNode,
                 Prism::ConstantPathOrWriteNode,
                 Prism::GlobalVariableOrWriteNode,
                 Prism::InstanceVariableOrWriteNode,
                 Prism::LocalVariableOrWriteNode
              "||="
            when Prism::ClassVariableOperatorWriteNode,
                 Prism::ConstantOperatorWriteNode,
                 Prism::ConstantPathOperatorWriteNode,
                 Prism::GlobalVariableOperatorWriteNode,
                 Prism::InstanceVariableOperatorWriteNode,
                 Prism::LocalVariableOperatorWriteNode
              "#{node.binary_operator}="
            else
              "="
            end

            @assigns << AssignNode.new(
              node.location,
              name,
              operator,
              T.must(call.arguments&.arguments&.first),
              T.must(call.arguments&.arguments&.last),
            )
          end
        end

        # Is this node a `T` or `::T` constant?
        #: (Prism::Node?) -> bool
        def t?(node)
          case node
          when Prism::ConstantReadNode
            node.name == :T
          when Prism::ConstantPathNode
            node.parent.nil? && node.name == :T
          else
            false
          end
        end

        # Is this node a `T.let` or `T.cast`?
        #: (Prism::CallNode) -> bool
        def t_annotation?(node)
          return false unless t?(node.receiver)
          return false unless ANNOTATION_METHODS.include?(node.name)
          return false unless node.arguments&.arguments&.size == 2

          true
        end
      end
    end
  end
end
