# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      # Translates Sorbet assertions to RBS comments.
      class SorbetAssertionsToRBSComments < Translator
        LINE_BREAK = "\n".ord #: Integer

        # @override
        #: (Prism::CallNode) -> void
        def visit_call_node(node)
          return super unless t_annotation?(node)

          value = T.must(node.arguments&.arguments&.first)
          rbs_annotation = build_rbs_annotation(node)

          if at_end_of_line?(node)
            # Handle regular case where T assertion is at end of line
            start_offset = node.location.start_offset
            end_offset = node.location.end_offset
            @rewriter << Source::Replace.new(start_offset, end_offset - 1, "#{dedent_value(node, value)} #{rbs_annotation}")
          elsif has_chained_method_call?(node)
            # Handle chained method calls (e.g., T.unsafe(a).b)
            start_offset = node.location.start_offset
            end_offset = node.location.end_offset

            # Find what comes after the T assertion on the same line
            line_end_offset = end_offset
            line_end_offset += 1 while line_end_offset < @ruby_bytes.size && @ruby_bytes[line_end_offset] != LINE_BREAK

            # Extract the chained part (everything after the T assertion on the same line)
            chained_bytes = @ruby_bytes[end_offset...line_end_offset]
            chained_part = chained_bytes ? chained_bytes.pack("C*") : ""

            # Find the start of the line to extract original indentation
            line_start_offset = start_offset
            line_start_offset -= 1 while line_start_offset > 0 && @ruby_bytes[line_start_offset - 1] != LINE_BREAK

            # Extract only the whitespace indentation at the beginning of the line
            indent_end_offset = line_start_offset
            indent_end_offset += 1 while indent_end_offset < start_offset && (@ruby_bytes[indent_end_offset] == " ".ord || @ruby_bytes[indent_end_offset] == "\t".ord)

            indent_bytes = @ruby_bytes[line_start_offset...indent_end_offset]
            original_indent = indent_bytes ? indent_bytes.pack("C*") : ""

            # Replace the entire line with the formatted version
            # Put the dot after the RBS annotation, and the method name on the next line with original indentation + 1 space
            replacement = "#{dedent_value(node, value)}. #{rbs_annotation}\n#{original_indent} #{chained_part.strip.delete_prefix(".")}"
            @rewriter << Source::Replace.new(start_offset, line_end_offset - 1, replacement)
          else
            # For other cases (comments, parentheses, etc.), don't translate
            super
          end
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

        # Is this node a `T.let`, `T.cast`, `T.must`, or `T.unsafe`?
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

        # Check if the T assertion is followed by a chained method call
        #: (Prism::CallNode) -> bool
        def has_chained_method_call?(node)
          end_offset = node.location.end_offset
          # Skip whitespace to find the next non-space character
          end_offset += 1 while end_offset < @ruby_bytes.size && @ruby_bytes[end_offset] == " ".ord

          # Check if the next character is a dot (direct method chaining)
          end_offset < @ruby_bytes.size && @ruby_bytes[end_offset] == ".".ord
        end
      end
    end
  end
end
