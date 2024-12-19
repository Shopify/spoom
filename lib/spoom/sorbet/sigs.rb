# typed: strict
# frozen_string_literal: true

require "rbi"

module Spoom
  module Sorbet
    class Sigs
      class << self
        extend T::Sig

        sig { params(ruby_contents: String).returns(String) }
        def strip(ruby_contents)
          sigs = collect_sigs(ruby_contents)
          lines_to_strip = sigs.flat_map { |sig, _| (sig.loc&.begin_line..sig.loc&.end_line).to_a }

          lines = []
          ruby_contents.lines.each_with_index do |line, index|
            lines << line unless lines_to_strip.include?(index + 1)
          end
          lines.join
        end

        sig { params(ruby_contents: String).returns(String) }
        def rbi_to_rbs(ruby_contents)
          ruby_contents = ruby_contents.dup
          sigs = collect_sigs(ruby_contents)

          sigs.each do |sig, node|
            scanner = Scanner.new(ruby_contents)
            start_index = scanner.find_char_position(
              T.must(sig.loc&.begin_line&.pred),
              T.must(sig.loc).begin_column,
            )
            end_index = scanner.find_char_position(
              sig.loc&.end_line&.pred,
              T.must(sig.loc).end_column,
            )
            ruby_contents[start_index...end_index] = SigTranslator.translate(sig, node)
          end

          ruby_contents
        end

        private

        sig { params(ruby_contents: String).returns(T::Array[[RBI::Sig, T.any(RBI::Method, RBI::Attr)]]) }
        def collect_sigs(ruby_contents)
          tree = RBI::Parser.parse_string(ruby_contents)
          visitor = SigsLocator.new
          visitor.visit(tree)
          visitor.sigs.sort_by { |sig, _rbs_string| -T.must(sig.loc&.begin_line) }
        end
      end

      class SigsLocator < RBI::Visitor
        extend T::Sig

        sig { returns(T::Array[[RBI::Sig, T.any(RBI::Method, RBI::Attr)]]) }
        attr_reader :sigs

        sig { void }
        def initialize
          super
          @sigs = T.let([], T::Array[[RBI::Sig, T.any(RBI::Method, RBI::Attr)]])
        end

        sig { override.params(node: T.nilable(RBI::Node)).void }
        def visit(node)
          return unless node

          case node
          when RBI::Method, RBI::Attr
            node.sigs.each do |sig|
              @sigs << [sig, node]
            end
          when RBI::Tree
            visit_all(node.nodes)
          end
        end
      end

      class SigTranslator
        class << self
          extend T::Sig

          sig { params(sig: RBI::Sig, node: T.any(RBI::Method, RBI::Attr)).returns(String) }
          def translate(sig, node)
            case node
            when RBI::Method
              translate_method_sig(sig, node)
            when RBI::Attr
              translate_attr_sig(sig, node)
            end
          end

          private

          sig { params(sig: RBI::Sig, node: RBI::Method).returns(String) }
          def translate_method_sig(sig, node)
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out, indent: sig.loc&.begin_column)

            if node.sigs.any?(&:is_final)
              p.printn("# @final")
              p.printt
            end

            if node.sigs.any?(&:is_abstract)
              p.printn("# @abstract")
              p.printt
            end

            if node.sigs.any?(&:is_override)
              if node.sigs.any?(&:allow_incompatible_override)
                p.printn("# @override(allow_incompatible: true)")
              else
                p.printn("# @override")
              end
              p.printt
            end

            if node.sigs.any?(&:is_overridable)
              p.printn("# @overridable")
              p.printt
            end

            p.print("#: ")
            p.send(:print_method_sig, node, sig)

            out.string
          end

          sig { params(sig: RBI::Sig, node: RBI::Attr).returns(String) }
          def translate_attr_sig(sig, node)
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out)
            p.print_attr_sig(node, sig)
            "#: #{out.string}"
          end
        end
      end

      # From https://github.com/Shopify/ruby-lsp/blob/9154bfc6ef/lib/ruby_lsp/document.rb#L127
      class Scanner
        extend T::Sig

        LINE_BREAK = T.let(0x0A, Integer)

        sig { params(source: String).void }
        def initialize(source)
          @current_line = T.let(0, Integer)
          @pos = T.let(0, Integer)
          @source = T.let(source.codepoints, T::Array[Integer])
        end

        # Finds the character index inside the source string for a given line and column
        sig { params(line: Integer, character: Integer).returns(Integer) }
        def find_char_position(line, character)
          # Find the character index for the beginning of the requested line
          until @current_line == line
            @pos += 1 until LINE_BREAK == @source[@pos]
            @pos += 1
            @current_line += 1
          end

          # The final position is the beginning of the line plus the requested column
          @pos + character
        end
      end
    end
  end
end
