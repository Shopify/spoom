# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      class RBSCommentsToSorbetSigs < Translator
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
