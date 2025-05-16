# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      class RBSCommentsToSorbetSigs < Translator
        # @override
        #: (Prism::DefNode node) -> void
        def visit_def_node(node)
          comments = node_rbs_comments(node)
          return if comments.empty?

          return if comments.signatures.empty?

          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Method

          comments.signatures.each do |signature|
            method_type = ::RBS::Parser.parse_method_type(signature.string)
            translator = RBI::RBS::MethodTypeTranslator.new(rbi_node)
            translator.visit(method_type)
            sig = translator.result
            apply_member_annotations(comments.annotations, sig)

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

          comments = node_rbs_comments(node)
          return if comments.empty?

          return if comments.signatures.empty?

          comments.signatures.each do |signature|
            attr_type = ::RBS::Parser.parse_type(signature.string)
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

            apply_member_annotations(comments.annotations, sig)

            @rewriter << Source::Replace.new(
              signature.location.start_offset,
              signature.location.end_offset,
              sig.string,
            )
          end
        end

        private

        #: (Prism::Node) -> RBSComments
        def node_rbs_comments(node)
          res = RBSComments.new

          comments = node_prism_comments(node)
          return res if comments.empty?

          comments.each do |comment|
            string = comment.slice

            if string.start_with?("# @")
              string = string.delete_prefix("#").strip
              res.annotations << RBSAnnotations.new(string)
            elsif string.start_with?("#: ")
              string = string.delete_prefix("#:").strip
              res.signatures << RBSSignature.new(string, comment.location)
            end
          end

          res
        end

        #: (Prism::Node) -> Array[Prism::Comment]
        def node_prism_comments(node)
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

        #: (Array[RBSAnnotations], RBI::Sig) -> void
        def apply_member_annotations(annotations, sig)
          annotations.each do |annotation|
            case annotation.string
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

        class RBSComments
          #: Array[RBSAnnotations]
          attr_reader :annotations

          #: Array[RBSSignature]
          attr_reader :signatures

          #: -> void
          def initialize
            @annotations = [] #: Array[RBSAnnotations]
            @signatures = [] #: Array[RBSSignature]
          end

          #: -> bool
          def empty?
            @annotations.empty? && @signatures.empty?
          end
        end

        class RBSAnnotations
          #: String
          attr_reader :string

          #: (String) -> void
          def initialize(string)
            @string = string
          end
        end

        class RBSSignature
          #: String
          attr_reader :string

          #: Prism::Location
          attr_reader :location

          #: (String, Prism::Location) -> void
          def initialize(string, location)
            @string = string
            @location = location
          end
        end
      end
    end
  end
end
