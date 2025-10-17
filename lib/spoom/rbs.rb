# typed: strict
# frozen_string_literal: true

module Spoom
  module RBS
    class Comments
      #: Array[Annotation]
      attr_reader :annotations

      #: Array[Signature]
      attr_reader :signatures

      #: -> void
      def initialize
        @annotations = [] #: Array[Annotation]
        @signatures = [] #: Array[Signature]
      end

      #: -> bool
      def empty?
        @annotations.empty? && @signatures.empty?
      end

      #: -> Array[Annotation]
      def class_annotations
        @annotations.select do |annotation|
          case annotation.string
          when "@abstract", "@interface", "@sealed", "@final"
            true
          when /^@requires_ancestor: /
            true
          else
            false
          end
        end
      end

      #: -> Array[Annotation]
      def method_annotations
        @annotations.select do |annotation|
          case annotation.string
          when "@abstract",
               "@final",
               "@override",
               "@override(allow_incompatible: true)",
               "@override(allow_incompatible: :visibility)",
               "@overridable",
               "@without_runtime"
            true
          else
            false
          end
        end
      end
    end

    class Comment
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

    class Annotation < Comment; end
    class Signature < Comment; end
    class TypeAlias < Comment; end

    module ExtractRBSComments
      #: (Prism::Node) -> Comments
      def node_rbs_comments(node)
        res = Comments.new

        comments = node.location.leading_comments.reverse
        return res if comments.empty?

        continuation_comments = [] #: Array[Prism::Comment]

        last_line = node.location.start_line

        comments.each do |comment|
          string = comment.slice

          comment_line = comment.location.end_line

          break if comment_line < last_line - 1

          last_line = comment_line

          if string.start_with?("# @")
            string = string.delete_prefix("#").strip
            res.annotations << Annotation.new(string, comment.location)
          elsif string.start_with?("#: ")
            string = string.delete_prefix("#:").strip
            location = comment.location

            continuation_comments.reverse_each do |continuation_comment|
              string = "#{string}#{continuation_comment.slice.delete_prefix("#|")}"
              location = location.join(continuation_comment.location)
            end
            continuation_comments.clear
            res.signatures << Signature.new(string, location)
          elsif string.start_with?("#|")
            continuation_comments << comment
          end
        end

        res
      end
    end
  end
end
