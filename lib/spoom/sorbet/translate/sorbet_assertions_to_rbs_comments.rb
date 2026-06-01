# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      # Translates Sorbet assertions to RBS comments.
      class SorbetAssertionsToRBSComments < Translator
        LINE_BREAK = "\n".ord #: Integer

        #: (
        #|  String,
        #|  file: String,
        #|  ?translate_t_let: bool,
        #|  ?translate_t_cast: bool,
        #|  ?translate_t_bind: bool,
        #|  ?translate_t_must: bool,
        #|  ?translate_t_unsafe: bool,
        #| ) -> void
        def initialize(
          ruby_contents,
          file:,
          translate_t_let: true,
          translate_t_cast: true,
          translate_t_bind: true,
          translate_t_must: true,
          translate_t_unsafe: true
        )
          super(ruby_contents, file: file)

          @translate_t_let = translate_t_let
          @translate_t_cast = translate_t_cast
          @translate_t_bind = translate_t_bind
          @translate_t_must = translate_t_must
          @translate_t_unsafe = translate_t_unsafe
        end

        # @override
        #: (Prism::StatementsNode) -> void
        def visit_statements_node(node)
          node.body.each do |statement|
            translated = maybe_translate_assertion(statement)
            visit(statement) unless translated
          end
        end

        # @override
        #: (Prism::IfNode) -> void
        def visit_if_node(node)
          if node.if_keyword_loc
            # We do not translate assertions in ternary expressions to avoid altering the semantic of the code.
            #
            # For example:
            # ```rb
            # a = T.must(b) ? T.must(c) : T.must(d)
            # ```
            #
            # would become
            # ```rb
            # a = T.must(b) ? T.must(c) : d #: !nil
            # ```
            #
            # which does not match the original intent.
            super
          end
        end

        private

        #: (Prism::Node) -> bool
        def maybe_translate_assertion(node)
          node = case node
          when Prism::MultiWriteNode,
               Prism::ClassVariableWriteNode, Prism::ClassVariableAndWriteNode, Prism::ClassVariableOperatorWriteNode, Prism::ClassVariableOrWriteNode,
               Prism::ConstantWriteNode, Prism::ConstantAndWriteNode, Prism::ConstantOperatorWriteNode, Prism::ConstantOrWriteNode,
               Prism::ConstantPathWriteNode, Prism::ConstantPathAndWriteNode, Prism::ConstantPathOperatorWriteNode, Prism::ConstantPathOrWriteNode,
               Prism::GlobalVariableWriteNode, Prism::GlobalVariableAndWriteNode,
               Prism::GlobalVariableOperatorWriteNode, Prism::GlobalVariableOrWriteNode,
               Prism::InstanceVariableWriteNode, Prism::InstanceVariableAndWriteNode,
               Prism::InstanceVariableOperatorWriteNode, Prism::InstanceVariableOrWriteNode,
               Prism::LocalVariableWriteNode, Prism::LocalVariableAndWriteNode, Prism::LocalVariableOperatorWriteNode, Prism::LocalVariableOrWriteNode,
               Prism::CallAndWriteNode, Prism::CallOperatorWriteNode, Prism::CallOrWriteNode
            node.value
          when Prism::CallNode
            node
          else
            return false
          end

          return false unless node.is_a?(Prism::CallNode)
          return false unless translatable_annotation?(node)
          return false unless at_end_of_line?(node)

          trailing_comment, comment_end_offset = extract_trailing_comment(node)
          # If extract_trailing_comment returns nil when there's an RBS annotation, don't translate
          return false if trailing_comment.nil? && has_rbs_annotation?(node)

          value = T.must(node.arguments&.arguments&.first)
          rbs_annotation = build_rbs_annotation(node)

          start_offset = node.location.start_offset
          # If there's a trailing comment, replace up to the end of the comment
          # Otherwise, replace up to the end of the node
          end_offset = comment_end_offset || node.location.end_offset

          replacement = if node.name == :bind
            "#{rbs_annotation}#{trailing_comment}"
          else
            "#{dedent_value(node, value)} #{rbs_annotation}#{trailing_comment}"
          end

          @rewriter << Source::Replace.new(start_offset, end_offset - 1, replacement)

          true
        end

        #: (Prism::CallNode) -> String
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
          when :bind
            srb_type = call.arguments&.arguments&.last #: as !nil
            rbs_type = RBI::Type.parse_node(srb_type).rbs_string
            "#: self as #{rbs_type}"
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
        def translatable_annotation?(node)
          return false unless t?(node.receiver)

          case node.name
          when :let
            return @translate_t_let && node.arguments&.arguments&.size == 2
          when :cast
            return @translate_t_cast && node.arguments&.arguments&.size == 2
          when :bind
            return @translate_t_bind && node.arguments&.arguments&.size == 2 && node.arguments&.arguments&.first.is_a?(Prism::SelfNode)
          when :must
            return @translate_t_must && node.arguments&.arguments&.size == 1
          when :unsafe
            return @translate_t_unsafe && node.arguments&.arguments&.size == 1
          end

          false
        end

        #: (Prism::Node) -> bool
        def at_end_of_line?(node)
          end_offset = node.location.end_offset
          end_offset += 1 while (@ruby_bytes[end_offset] == " ".ord) && (end_offset < @ruby_bytes.size)
          # Check if we're at a newline OR at the start of a comment
          @ruby_bytes[end_offset] == LINE_BREAK || @ruby_bytes[end_offset] == "#".ord
        end

        # Check if the node has an RBS annotation comment (#:) after it
        #: (Prism::Node) -> bool
        def has_rbs_annotation?(node)
          end_offset = node.location.end_offset
          # Skip spaces
          end_offset += 1 while (@ruby_bytes[end_offset] == " ".ord) && (end_offset < @ruby_bytes.size)
          # Check if there's a comment starting with #:
          @ruby_bytes[end_offset] == "#".ord && @ruby_bytes[end_offset + 1] == ":".ord
        end

        # Extract any trailing comment after the node
        # Returns [comment_text, comment_end_offset] or [nil, nil] if no comment or RBS annotation
        #: (Prism::Node) -> [String?, Integer?]
        def extract_trailing_comment(node)
          end_offset = node.location.end_offset
          # Skip spaces
          end_offset += 1 while (@ruby_bytes[end_offset] == " ".ord) && (end_offset < @ruby_bytes.size)
          # Check if there's a comment
          return [nil, nil] unless @ruby_bytes[end_offset] == "#".ord

          # If it's an RBS annotation comment (#:), return nil to prevent translation
          return [nil, nil] if @ruby_bytes[end_offset + 1] == ":".ord

          # Find the end of the comment (end of line)
          comment_start = end_offset
          end_offset += 1 while @ruby_bytes[end_offset] != LINE_BREAK && end_offset < @ruby_bytes.size

          # Extract the comment including the leading space and return the end offset
          range = @ruby_bytes[comment_start...end_offset] #: as !nil
          [" #{range.pack("C*")}", end_offset]
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
