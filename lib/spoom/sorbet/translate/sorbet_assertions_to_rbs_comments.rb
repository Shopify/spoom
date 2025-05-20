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
          return super unless at_end_of_line?(node)

          value = T.must(node.arguments&.arguments&.first)
          rbs_annotation = build_rbs_annotation(node)

          start_offset = node.location.start_offset
          end_offset = node.location.end_offset
          @rewriter << Source::Replace.new(start_offset, end_offset - 1, "#{dedent_value(node, value)} #{rbs_annotation}")
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
      end
    end
  end
end
