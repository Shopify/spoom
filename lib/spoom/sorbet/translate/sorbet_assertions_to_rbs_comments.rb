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

          # Skip translation if inside string interpolation
          if inside_string_interpolation?(node)
            super
            return
          end

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

            # Check if T assertion is at the beginning of the line (after indentation)
            prefix_bytes = @ruby_bytes[indent_end_offset...start_offset]
            prefix = prefix_bytes ? prefix_bytes.pack("C*") : ""

            if prefix.strip.empty? || prefix.strip.end_with?("=")
              # T assertion is at the beginning of the line or simple assignment - simple case
              replacement = "#{dedent_value(node, value)}. #{rbs_annotation}\n#{original_indent} #{chained_part.strip.delete_prefix(".")}"
              @rewriter << Source::Replace.new(start_offset, line_end_offset - 1, replacement)
            elsif chained_part.include?(")")
              # T assertion is inside a more complex expression - need to break into multiple lines
              closing_paren_index = chained_part.rindex(")")
              method_part = chained_part[0...closing_paren_index].strip.delete_prefix(".")
              closing_part = chained_part[closing_paren_index..-1]

              # Parse method arguments if they exist
              args_part = ""
              method_has_args = chained_part.include?(",")
              if method_has_args
                # Find arguments after the method call
                comma_index = method_part.index(",")
                if comma_index
                  actual_method = method_part[0...comma_index].strip
                  args_text = method_part[comma_index..-1]
                  # Split arguments and format each on its own line
                  args = args_text.split(",").map(&:strip).reject(&:empty?)
                  formatted_args = args.map { |arg| "#{original_indent}  #{arg}," }.join("\n")
                  method_part = "#{actual_method}," # Add trailing comma to method name
                  args_part = "\n#{formatted_args}" unless args.empty?
                end
              end

              # Check if prefix already ends with an opening parenthesis
              replacement = if prefix.rstrip.end_with?("(")
                # Format with line breaks, don't add extra opening parenthesis
                "#{prefix.rstrip}\n#{original_indent}  #{dedent_value(node, value)}. #{rbs_annotation}\n#{original_indent}   #{method_part}#{args_part}\n#{original_indent}#{closing_part}"
              else
                # Format with line breaks and add opening parenthesis
                "\n#{original_indent}#{prefix.rstrip}(\n#{original_indent}  #{dedent_value(node, value)}. #{rbs_annotation}\n#{original_indent}   #{method_part}#{args_part}\n#{original_indent}#{closing_part}"
              end
              @rewriter << Source::Replace.new(line_start_offset + original_indent.length, line_end_offset - 1, replacement)
            # Find the closing parenthesis position
            else
              # Fallback to simple case
              replacement = "#{dedent_value(node, value)}. #{rbs_annotation}\n#{original_indent} #{chained_part.strip.delete_prefix(".")}"
              @rewriter << Source::Replace.new(start_offset, line_end_offset - 1, replacement)
            end
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

        # Check if the node is inside string interpolation
        #: (Prism::CallNode) -> bool
        def inside_string_interpolation?(node)
          start_offset = node.location.start_offset

          # Find the start of the current line
          line_start = start_offset
          line_start -= 1 while line_start > 0 && @ruby_bytes[line_start - 1] != LINE_BREAK

          # Find the end of the current line
          line_end = start_offset
          line_end += 1 while line_end < @ruby_bytes.size && @ruby_bytes[line_end] != LINE_BREAK

          # Get the line content as a string
          line_bytes = @ruby_bytes[line_start...line_end]
          line_content = line_bytes ? line_bytes.pack("C*") : ""

          # Simple check: if the line contains #{ before our node and } after it, we're in interpolation
          node_position_in_line = start_offset - line_start
          line_before_node = line_content[0...node_position_in_line]
          line_after_node = line_content[node_position_in_line..-1]

          # Check for interpolation pattern: #{...T.method...}
          interpolation_start = line_before_node.rindex('#{')
          return false unless interpolation_start

          # Make sure there's a closing } after the node
          line_after_node.include?("}")
        end
      end
    end
  end
end
