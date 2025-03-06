# typed: strict
# frozen_string_literal: true

require "rbi"

module Spoom
  module Sorbet
    class Assertions
      class Error < Spoom::Error; end

      class << self
        extend T::Sig

        #: (String, file: String, ?let: bool, ?cast: bool) -> String
        def rbi_to_rbs(ruby_contents, file:, let: true, cast: true)
          old_encoding = ruby_contents.encoding
          ruby_contents = ruby_contents.encode("UTF-8") unless old_encoding == "UTF-8"
          ruby_bytes = ruby_contents.bytes

          assigns = collect_assigns(ruby_contents, file: file, let: let, cast: cast)

          assigns.reverse.each do |assign|
            # Adjust the end offset to locate the end of the line:
            #
            # So this:
            #
            #     (a = T.let(nil, T.nilable(String)))
            #
            # properly becomes:
            #
            #     (a = nil) #: String?
            #
            # This is important to avoid translating the `nil` as `nil` instead of `nil #: String?`
            end_offset = assign.node.location.end_offset
            end_offset += 1 while (ruby_bytes[end_offset] != "\n".ord) && (end_offset < ruby_bytes.size)

            # Insert the comment at the end of the line:
            T.unsafe(ruby_bytes).insert(end_offset, *" #{assign.rbs_comment}".bytes)

            # Rewrite the value
            start_offset = assign.operator_loc.end_offset
            end_offset = assign.node.value.location.start_offset + assign.node.value.location.length
            ruby_bytes[start_offset...end_offset] = " #{dedent_value(assign)}".bytes
          end

          ruby_bytes.pack("C*").force_encoding(old_encoding)
        end

        private

        #: (String, file: String, let: bool, cast: bool) -> Array[AssignNode]
        def collect_assigns(ruby_contents, file:, let:, cast:)
          node = Spoom.parse_ruby(ruby_contents, file: file)
          visitor = Locator.new(let: let, cast: cast)
          visitor.visit(node)
          visitor.assigns
        end

        #: (AssignNode) -> String
        def dedent_value(assign)
          if assign.value.location.start_line == assign.node.location.start_line
            # The value is on the same line as the assign, so we can just return the slice as is:
            # ```rb
            # a = T.let(nil, T.nilable(String))
            # ```
            # becomes
            # ```rb
            # a = nil #: String?
            # ```
            return assign.value.slice
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
          indent = assign.value.location.start_line - assign.node.location.start_line
          lines = assign.value.slice.lines
          if lines.size > 1
            lines[1..]&.each_with_index do |line, i|
              lines[i + 1] = line.delete_prefix("  " * indent)
            end
          end
          lines.join
        end
      end

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

      class AssignNode
        extend T::Sig

        ALLOWED_KINDS = T.let([:let, :cast], T::Array[Symbol])

        #: AssignType
        attr_reader :node

        #: Prism::Location
        attr_reader :operator_loc

        #: Prism::Node
        attr_reader :value, :type

        #: Symbol
        attr_reader :kind # should be one of [:let, :cast]

        #: (AssignType, Prism::Location, Prism::Node, Prism::Node, Symbol) -> void
        def initialize(node, operator_loc, value, type, kind)
          @node = node
          @operator_loc = operator_loc
          @value = value
          @type = type

          unless ALLOWED_KINDS.include?(kind)
            raise Error, "Unknown assign kind: `#{kind}`, expected one of #{ALLOWED_KINDS.inspect}"
          end

          @kind = kind
        end

        #: -> String
        def rbs_comment
          rbs_type = RBI::Type.parse_node(type).rbs_string

          case kind
          when :let
            "#: #{rbs_type}"
          when :cast
            "#: as #{rbs_type}"
          else
            raise Error, "Unknown assign kind: #{kind}"
          end
        end
      end

      class Locator < Spoom::Visitor
        extend T::Sig

        #: Array[AssignNode]
        attr_reader :assigns

        #: (let: bool, cast: bool) -> void
        def initialize(let:, cast:)
          @annotation_methods = T.let([], T::Array[Symbol])
          @annotation_methods << :let if let
          @annotation_methods << :cast if cast

          super()
          @assigns = T.let([], T::Array[AssignNode])
        end

        #: (AssignType) -> void
        def visit_assign(node)
          call = node.value
          return unless call.is_a?(Prism::CallNode) && t_annotation?(call)

          # We do not support translating heredocs yet because the `#: ` would need to be added to the first line
          # and it will requires us to adapt the annotation detection in Sorbet. But Sorbet desugars them into bare
          # strings making them impossible to detect.
          value = T.must(call.arguments&.arguments&.first)
          return if contains_heredoc?(value)

          operator_loc = case node
          when Prism::ClassVariableOperatorWriteNode,
                Prism::ConstantOperatorWriteNode,
                Prism::ConstantPathOperatorWriteNode,
                Prism::GlobalVariableOperatorWriteNode,
                Prism::InstanceVariableOperatorWriteNode,
                Prism::LocalVariableOperatorWriteNode
            node.binary_operator_loc
          else
            node.operator_loc
          end

          @assigns << AssignNode.new(
            node,
            operator_loc,
            value,
            T.must(call.arguments&.arguments&.last),
            call.name,
          )
        end

        alias_method(:visit_class_variable_and_write_node, :visit_assign)
        alias_method(:visit_class_variable_operator_write_node, :visit_assign)
        alias_method(:visit_class_variable_or_write_node, :visit_assign)
        alias_method(:visit_class_variable_write_node, :visit_assign)

        alias_method(:visit_constant_and_write_node, :visit_assign)
        alias_method(:visit_constant_operator_write_node, :visit_assign)
        alias_method(:visit_constant_or_write_node, :visit_assign)
        alias_method(:visit_constant_write_node, :visit_assign)

        alias_method(:visit_constant_path_and_write_node, :visit_assign)
        alias_method(:visit_constant_path_operator_write_node, :visit_assign)
        alias_method(:visit_constant_path_or_write_node, :visit_assign)
        alias_method(:visit_constant_path_write_node, :visit_assign)

        alias_method(:visit_global_variable_and_write_node, :visit_assign)
        alias_method(:visit_global_variable_operator_write_node, :visit_assign)
        alias_method(:visit_global_variable_or_write_node, :visit_assign)
        alias_method(:visit_global_variable_write_node, :visit_assign)

        alias_method(:visit_instance_variable_and_write_node, :visit_assign)
        alias_method(:visit_instance_variable_operator_write_node, :visit_assign)
        alias_method(:visit_instance_variable_or_write_node, :visit_assign)
        alias_method(:visit_instance_variable_write_node, :visit_assign)

        alias_method(:visit_local_variable_and_write_node, :visit_assign)
        alias_method(:visit_local_variable_operator_write_node, :visit_assign)
        alias_method(:visit_local_variable_or_write_node, :visit_assign)
        alias_method(:visit_local_variable_write_node, :visit_assign)

        alias_method(:visit_multi_write_node, :visit_assign)

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
          return false unless @annotation_methods.include?(node.name)
          return false unless node.arguments&.arguments&.size == 2

          true
        end

        #: (Prism::Node) -> bool
        def contains_heredoc?(node)
          visitor = HeredocVisitor.new
          visitor.visit(node)
          visitor.contains_heredoc
        end

        class HeredocVisitor < Spoom::Visitor
          extend T::Sig

          #: bool
          attr_reader :contains_heredoc

          #: -> void
          def initialize
            @contains_heredoc = T.let(false, T::Boolean)

            super
          end

          # @override
          #: (Prism::Node?) -> void
          def visit(node)
            return if node.nil?

            case node
            when Prism::StringNode, Prism::InterpolatedStringNode
              return @contains_heredoc = !!node.opening_loc&.slice&.match?(/<<~|<<-/)
            end

            super
          end
        end
      end
    end
  end
end
