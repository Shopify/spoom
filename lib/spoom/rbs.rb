# typed: strict
# frozen_string_literal: true

module Spoom
  module RBS
    class Comments
      #: Array[Annotations]
      attr_reader :annotations

      #: Array[Signature]
      attr_reader :signatures

      #: -> void
      def initialize
        @annotations = [] #: Array[Annotations]
        @signatures = [] #: Array[Signature]
      end

      #: -> bool
      def empty?
        @annotations.empty? && @signatures.empty?
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

    class Annotations < Comment; end
    class Signature < Comment; end

    module ExtractRBSComments
      #: (Prism::Node) -> Comments
      def node_rbs_comments(node)
        res = Comments.new

        comments = node.location.leading_comments.reverse
        return res if comments.empty?

        continuation_comments = [] #: Array[Prism::Comment]

        comments.each do |comment|
          string = comment.slice

          if string.start_with?("# @")
            string = string.delete_prefix("#").strip
            res.annotations << Annotations.new(string, comment.location)
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
