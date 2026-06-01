# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      # @abstract
      class Translator < Spoom::Visitor
        #: (String, file: String) -> void
        def initialize(ruby_contents, file:)
          super()

          @file = file #: String

          @original_encoding = ruby_contents.encoding #: Encoding
          @ruby_contents = if @original_encoding == "UTF-8"
            ruby_contents
          else
            ruby_contents.encode("UTF-8")
          end #: String

          node, comments = Spoom.parse_ruby(ruby_contents, file: file)
          @node = node #: Prism::Node
          @comments = comments #: Array[Prism::Comment]
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

        # Consume the next blank line if any
        #: (Integer) -> Integer
        def adjust_to_new_line(offset)
          if offset + 1 < @ruby_bytes.size && @ruby_bytes[offset + 1] == "\n".ord
            offset += 1
          end

          offset
        end
      end
    end
  end
end
