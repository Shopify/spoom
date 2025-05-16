# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      # Translates Sorbet assertions to RBS comments.
      class SorbetAssertionsToRBSComments < Translator
        LINE_BREAK = "\n".ord #: Integer

        #: (String, file: String) -> void
        def initialize(ruby_contents, file:)
          super

          @nodes_nesting = [] #: Array[Prism::Node]
        end

        # @override
        #: (Prism::Node?) -> void
        def visit(node)
          return unless node

          @nodes_nesting << node
          super
          @nodes_nesting.pop
        end

        # @override
        #: (Prism::CallNode) -> void
        def visit_call_node(node)
          return super unless t_annotation?(node)

          value = T.must(node.arguments&.arguments&.first)
          rbs_annotation = build_rbs_annotation(node)

          start_offset = node.location.start_offset
          end_offset = node.location.end_offset

          new_string = if at_end_of_line?(node)
            "#{dedent_value(node, value)} #{rbs_annotation}"
          # elsif parent = @nodes_nesting.grep(Prism::ArgumentsNode).last
          #   if node.location.start_line == parent.location.start_line
          #     start_of_line = node.location.start_line_slice[/\A */]&.size || 0
          #     indent = " " * (start_of_line + 2)
          #     if next_token(end_offset) == ",".ord
          #       end_offset += 1
          #       if next_token(end_offset) == " ".ord
          #         end_offset += 1
          #       end
          #       res = "\n#{indent}#{dedent_value(node, value)}, #{rbs_annotation}\n#{indent}"
          #     else
          #       res = "\n#{indent}#{dedent_value(node, value)} #{rbs_annotation}\n#{indent}"
          #     end
          #   else
          #     return
          #   end
          elsif !has_comment?(node)
            puts @nodes_nesting.map(&:class).join(" > ")
            start_of_line = node.location.start_line_slice[/\A */]&.size || 0
            indent = " " * (start_of_line + 2)
            if next_token(end_offset) == ",".ord
              end_offset += 1
              end_offset += 1 while next_token(end_offset) == " ".ord
              "#{dedent_value(node, value)}, #{rbs_annotation}\n#{indent}"
            else
              "#{dedent_value(node, value)} #{rbs_annotation}\n#{indent}"
            end
          else
            return
          end

          @rewriter << Source::Replace.new(start_offset, end_offset - 1, new_string)
        end

        private

        #: (Prism::CallNode) -> void
        def build_rbs_annotation(call)
          case call.name
          when :let
            srb_type = call.arguments&.arguments&.last #: as !nil
            rbs_type = RBI::Type.parse_node(srb_type).rbs_string
            "#: #{rbs_type}"
          when :cast
            srb_type = call.arguments&.arguments&.last #: as !nil
            rbs_type = RBI::Type.parse_node(srb_type).rbs_string
            "#: as #{rbs_type}"
          when :must
            "#: as !nil"
          when :unsafe
            "#: as untyped"
          else
            raise "Unknown annotation method: #{call.name}"
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

          case node.name
          when :let, :cast
            return node.arguments&.arguments&.size == 2
          when :must, :unsafe
            return node.arguments&.arguments&.size == 1
          end

          false
        end

        #: (Prism::Node) -> bool
        def at_end_of_line?(node)
          end_offset = node.location.end_offset
          end_offset += 1 while (@ruby_bytes[end_offset] == " ".ord) && (end_offset < @ruby_bytes.size)
          @ruby_bytes[end_offset] == LINE_BREAK
        end

        #: (Prism::Node, Prism::Node) -> String
        def dedent_value(assign, value)
          if value.location.start_line == assign.location.start_line
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
          indent = value.location.start_line - assign.location.start_line
          lines = value.slice.lines
          if lines.size > 1
            lines[1..]&.each_with_index do |line, i|
              lines[i + 1] = line.delete_prefix("  " * indent)
            end
          end
          lines.join
        end

        #: (Prism::Node) -> bool
        def has_comment?(node)
          offset = node.location.end_offset
          offset += 1 while next_token(offset) == " ".ord
          next_token(offset) == "#".ord
        end

        #: (Integer) -> Integer?
        def next_token(offset)
          return if offset >= @ruby_bytes.size

          @ruby_bytes[offset]
        end
      end
    end
  end
end
