# typed: strict
# frozen_string_literal: true

require "rbi"

module Spoom
  module Sorbet
    class Sigs
      class Error < Spoom::Error; end

      class << self
        # Deletes all `sig` nodes from the given Ruby code.
        # It doesn't handle type members and class annotations.
        #: (String ruby_contents) -> String
        def strip(ruby_contents)
          StripSorbetSigsRewriter.new(ruby_contents, file: "test.rb").rewrite
        end

        # Converts all `sig` nodes to RBS comments in the given Ruby code.
        # It also handles type members and class annotations.
        #: (String ruby_contents, ?positional_names: bool) -> String
        def rbi_to_rbs(ruby_contents, positional_names: true)
          SorbetSigsToRBSCommentsRewriter.new(ruby_contents, file: "test.rb", positional_names: positional_names).rewrite
        end

        # Converts all the RBS comments in the given Ruby code to `sig` nodes.
        # It also handles type members and class annotations.
        #: (String ruby_contents) -> String
        def rbs_to_rbi(ruby_contents)
          RBSCommentsToSorbetSigsRewriter.new(ruby_contents, file: "test.rb").rewrite
        end
      end

      # @abstract
      class Rewriter < Spoom::Visitor
        #: (String, file: String) -> void
        def initialize(ruby_contents, file:)
          super()

          @file = file #: String

          @ruby_contents = if ruby_contents.encoding == "UTF-8"
            ruby_contents
          else
            ruby_contents.encode("UTF-8")
          end #: String

          node, comments = Spoom.parse_ruby_with_comments(ruby_contents, file: file)
          @node = node #: Prism::Node
          @comments_by_line = comments.to_h { |c| [c.location.start_line, c] } #: Hash[Integer, Prism::Comment]
          @original_encoding = ruby_contents.encoding #: Encoding
          @ruby_bytes = ruby_contents.bytes #: Array[Integer]
          @rewriter = Spoom::Source::Rewriter.new #: Source::Rewriter
        end

        #: -> String
        def rewrite
          visit(@node)
          @rewriter.rewrite!(@ruby_bytes)
          @ruby_bytes.pack("C*").force_encoding(@original_encoding)
        end

        private

        #: (Prism::CallNode node) -> bool
        def sorbet_sig?(node)
          return false unless node.message == "sig"

          recv = node.receiver
          return false if recv && !recv.is_a?(Prism::SelfNode) && !recv.slice.match?(/(::)?T::Sig::WithoutRuntime/)

          true
        end

        #: (Integer) -> Integer
        def adjust_to_line_start(offset)
          offset -= 1 while offset > 0 && @ruby_bytes[offset - 1] != "\n".ord
          offset
        end

        #: (Integer) -> Integer
        def adjust_to_line_end(offset)
          offset += 1 while offset < @ruby_bytes.size && @ruby_bytes[offset] != "\n".ord
          offset
        end
      end

      # Deletes all `sig` nodes from the given Ruby code.
      # It doesn't handle type members and class annotations.
      class StripSorbetSigsRewriter < Rewriter
        # @override
        #: (Prism::CallNode node) -> void
        def visit_call_node(node)
          return unless sorbet_sig?(node)

          @rewriter << Source::Delete.new(
            adjust_to_line_start(node.location.start_offset),
            adjust_to_line_end(node.location.end_offset),
          )
        end
      end

      # Converts all `sig` nodes to RBS comments in the given Ruby code.
      # It also handles type members and class annotations.
      class SorbetSigsToRBSCommentsRewriter < Rewriter
        #: (String, file: String, positional_names: bool) -> void
        def initialize(ruby_contents, file:, positional_names:)
          super(ruby_contents, file: file)

          @positional_names = positional_names #: bool
          @last_sigs = [] #: Array[[Prism::CallNode, RBI::Sig]]
        end

        # @override
        #: (Prism::DefNode) -> void
        def visit_def_node(node)
          return if @last_sigs.empty?
          return if @last_sigs.any? { |_, sig| sig.is_abstract }

          apply_member_annotations(@last_sigs)

          # Build the RBI::Method node so we can print the method signature as RBS.
          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Method

          @last_sigs.each do |node, sig|
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out, indent: node.location.start_column, positional_names: @positional_names)
            p.print("#: ")
            p.send(:print_method_sig, rbi_node, sig)
            p.print("\n")
            @rewriter << Source::Replace.new(node.location.start_offset, node.location.end_offset, out.string)
          end

          @last_sigs.clear
        end

        # @override
        #: (Prism::CallNode) -> void
        def visit_call_node(node)
          case node.message
          when "sig"
            visit_sig(node)
          when "attr_reader", "attr_writer", "attr_accessor"
            visit_attr(node)
          else
            super
          end
        end

        private

        #: (Prism::CallNode) -> void
        def visit_sig(node)
          return unless sorbet_sig?(node)

          builder = RBI::Parser::SigBuilder.new(@ruby_contents, file: @file)
          builder.current.loc = node.location
          builder.visit_call_node(node)
          builder.current.comments = []

          @last_sigs << [node, builder.current]
        end

        #: (Prism::CallNode) -> void
        def visit_attr(node)
          unless node.message == "attr_reader" || node.message == "attr_writer" || node.message == "attr_accessor"
            raise Error, "Expected attr_reader, attr_writer, or attr_accessor"
          end

          return if @last_sigs.empty?
          return if @last_sigs.any? { |_, sig| sig.is_abstract }

          apply_member_annotations(@last_sigs)

          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Attr

          @last_sigs.each do |node, sig|
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out, indent: node.location.start_column, positional_names: @positional_names)
            p.print("#: ")
            p.print_attr_sig(rbi_node, sig)
            p.print("\n")
            @rewriter << Source::Replace.new(node.location.start_offset, node.location.end_offset, out.string)
          end

          @last_sigs.clear
        end

        #: (Array[[Prism::CallNode, RBI::Sig]]) -> void
        def apply_member_annotations(sigs)
          return if sigs.empty?

          node, _sig = sigs.first #: as [Prism::CallNode, RBI::Sig]
          insert_pos = node.location.start_offset

          if sigs.any? { |_, sig| sig.without_runtime }
            @rewriter << Source::Insert.new(insert_pos, "# @without_runtime\n")
          end

          if sigs.any? { |_, sig| sig.is_final }
            @rewriter << Source::Insert.new(insert_pos, "# @final\n")
          end

          if sigs.any? { |_, sig| sig.is_abstract }
            @rewriter << Source::Insert.new(insert_pos, "# @abstract\n")
          end

          if sigs.any? { |_, sig| sig.is_override }
            @rewriter << if sigs.any? { |_, sig| sig.allow_incompatible_override }
              Source::Insert.new(insert_pos, "# @override(allow_incompatible: true)\n")
            else
              Source::Insert.new(insert_pos, "# @override\n")
            end
          end

          if sigs.any? { |_, sig| sig.is_overridable }
            @rewriter << Source::Insert.new(insert_pos, "# @overridable\n")
          end
        end
      end

      class RBSCommentsToSorbetSigsRewriter < Rewriter
        # @override
        #: (Prism::DefNode node) -> void
        def visit_def_node(node)
          comments = node_comments(node)
          return if comments.empty?

          annotations = comments.select { |c| c.slice.start_with?("# @") }
          signatures = comments.select { |c| c.slice.start_with?("#: ") }

          return if signatures.empty?

          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Method

          signatures.each do |signature|
            method_type = ::RBS::Parser.parse_method_type(signature.slice.delete_prefix("#: "))
            translator = RBI::RBS::MethodTypeTranslator.new(rbi_node)
            translator.visit(method_type)
            sig = translator.result
            apply_member_annotations(annotations, sig)

            @rewriter << Source::Replace.new(
              signature.location.start_offset,
              signature.location.end_offset,
              sig.string,
            )
          rescue ::RBS::ParsingError
            # Ignore signatures with errors
            next
          end
        end

        # @override
        #: (Prism::CallNode node) -> void
        def visit_call_node(node)
          return unless node.message == "attr_reader" || node.message == "attr_writer" || node.message == "attr_accessor"

          comments = node_comments(node)
          return if comments.empty?

          annotations = comments.select { |c| c.slice.start_with?("# @") }
          signatures = comments.select { |c| c.slice.start_with?("#: ") }

          return if signatures.empty?

          signatures.each do |signature|
            attr_type = ::RBS::Parser.parse_type(signature.slice.delete_prefix("#: "))
            sig = RBI::Sig.new

            if node.message == "attr_writer"
              if node.arguments&.arguments&.size != 1
                raise Error, "AttrWriter must have exactly one name"
              end

              name = node.arguments&.arguments&.first #: as Prism::SymbolNode
              sig.params << RBI::SigParam.new(
                name.slice[1..-1], #: as String
                RBI::RBS::TypeTranslator.translate(attr_type),
              )
            end

            sig.return_type = RBI::RBS::TypeTranslator.translate(attr_type)

            apply_member_annotations(annotations, sig)

            @rewriter << Source::Replace.new(
              signature.location.start_offset,
              signature.location.end_offset,
              sig.string,
            )
          end
        end

        private

        #: (Prism::Node) -> Array[Prism::Comment]
        def node_comments(node)
          comments = []

          start_line = node.location.start_line
          start_line -= 1 unless @comments_by_line.key?(start_line)

          start_line.downto(1) do |line|
            comment = @comments_by_line[line]
            break unless comment

            comments.unshift(comment)
            @comments_by_line.delete(line)
          end

          comments
        end

        #: (Array[Prism::Comment], RBI::Sig) -> void
        def apply_member_annotations(comments, sig)
          comments.each do |comment|
            case comment.slice.delete_prefix("# ")
            when "@abstract"
              sig.is_abstract = true
            when "@final"
              sig.is_final = true
            when "@override"
              sig.is_override = true
            when "@override(allow_incompatible: true)"
              sig.is_override = true
              sig.allow_incompatible_override = true
            when "@overridable"
              sig.is_overridable = true
            when "@without_runtime"
              sig.without_runtime = true
            end
          end
        end
      end
    end
  end
end
