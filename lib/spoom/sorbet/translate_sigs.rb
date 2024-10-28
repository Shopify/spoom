# typed: strict
# frozen_string_literal: true

require "rbi"

module Spoom
  module Sorbet
    class TranslateSigs
      class << self
        extend T::Sig

        sig { params(ruby_contents: String).returns(String) }
        def rbi_to_rbs(ruby_contents)
          ruby_contents = ruby_contents.dup

          tree = RBI::Parser.parse_string(ruby_contents)

          translator = RBI2RBS.new
          translator.visit(tree)
          sigs = translator.sigs.sort_by { |sig, _rbs_string| -T.must(sig.loc&.begin_line) }

          sigs.each do |sig, rbs_string|
            scanner = Scanner.new(ruby_contents, Encoding::UTF_8)
            start_index = scanner.find_char_position(
              line: T.must(sig.loc&.begin_line) - 1,
              character: T.must(sig.loc).begin_column,
            )
            end_index = scanner.find_char_position(
              line: sig.loc&.end_line&.-(1),
              character: T.must(sig.loc).end_column,
            )
            ruby_contents[start_index...end_index] = rbs_string
          end

          ruby_contents
        end
      end

      class RBI2RBS < RBI::Visitor
        extend T::Sig

        sig { returns(T::Array[[RBI::Sig, String]]) }
        attr_reader :sigs

        sig { void }
        def initialize
          super
          @sigs = T.let([], T::Array[[RBI::Sig, String]])
        end

        sig { override.params(node: T.nilable(RBI::Node)).void }
        def visit(node)
          return unless node

          case node
          when RBI::Method
            translate_method_sigs(node)
          when RBI::Attr
            translate_attr_sigs(node)
          when RBI::Tree
            visit_all(node.nodes)
          end

          super
        end

        private

        sig { params(node: RBI::Method).void }
        def translate_method_sigs(node)
          node.sigs.each do |sig|
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out, indent: sig.loc&.begin_column)

            if node.sigs.any?(&:is_abstract)
              p.printn("# @abstract")
              p.printt
            end

            if node.sigs.any?(&:is_override)
              p.printn("# @override")
              p.printt
            end

            if node.sigs.any?(&:is_overridable)
              p.printn("# @overridable")
              p.printt
            end

            p.print("#: ")
            p.send(:print_method_sig, node, sig)

            @sigs << [sig, out.string]
          end
        end

        sig { params(node: RBI::Attr).void }
        def translate_attr_sigs(node)
          node.sigs.each do |sig|
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out)
            p.print_attr_sig(node, sig)
            @sigs << [sig, "#: #{out.string}"]
          end
        end
      end

      # From https://github.com/Shopify/ruby-lsp/blob/9154bfc6ef/lib/ruby_lsp/document.rb#L127
      class Scanner
        extend T::Sig

        LINE_BREAK = T.let(0x0A, Integer)

        # After character 0xFFFF, UTF-16 considers characters to have length 2 and we have to account for that
        SURROGATE_PAIR_START = T.let(0xFFFF, Integer)

        sig { params(source: String, encoding: Encoding).void }
        def initialize(source, encoding)
          @current_line = T.let(0, Integer)
          @pos = T.let(0, Integer)
          @source = T.let(source.codepoints, T::Array[Integer])
          @encoding = encoding
        end

        # Finds the character index inside the source string for a given line and column
        sig { params(position: T::Hash[Symbol, T.untyped]).returns(Integer) }
        def find_char_position(position)
          # Find the character index for the beginning of the requested line
          until @current_line == position[:line]
            @pos += 1 until LINE_BREAK == @source[@pos]
            @pos += 1
            @current_line += 1
          end

          # The final position is the beginning of the line plus the requested column. If the encoding is UTF-16,
          # we also need to adjust for surrogate pairs
          requested_position = @pos + position[:character]

          if @encoding == Encoding::UTF_16LE
            requested_position -= utf_16_character_position_correction(@pos, requested_position)
          end

          requested_position
        end

        # Subtract 1 for each character after 0xFFFF in the current line from the column position, so that we hit the
        # right character in the UTF-8 representation
        sig { params(current_position: Integer, requested_position: Integer).returns(Integer) }
        def utf_16_character_position_correction(current_position, requested_position)
          utf16_unicode_correction = 0

          until current_position == requested_position
            codepoint = @source[current_position]
            utf16_unicode_correction += 1 if codepoint && codepoint > SURROGATE_PAIR_START

            current_position += 1
          end

          utf16_unicode_correction
        end
      end
    end
  end
end
