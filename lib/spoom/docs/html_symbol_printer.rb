# typed: strict
# frozen_string_literal: true

module Spoom
  module Docs
    class HTMLSymbolPrinter
      extend T::Sig

      sig do
        params(
          client: LSP::Client,
          uri: String,
          html: String
        ).void
      end
      def initialize(client, uri, html)
        @client = client
        @uri = uri
        @html = html
      end

      sig { params(symbols: T::Array[LSP::DocumentSymbol]).void }
      def visit_symbols(symbols)
        symbols.each do |symbol|
          visit_symbol(symbol)
        end
      end

      sig { params(symbol: LSP::DocumentSymbol).void }
      def visit_symbol(symbol)
        @html << "<div>"
        @html << "<h3>#{symbol.name}</h3>"
        loc = symbol.range
        if loc
          hover = @client.hover(@uri, loc.start.line, loc.start.char)
          if hover
            hover_string = hover.contents
            hover_sections = hover_string.split("\n---\n", 2)
            if hover_sections.size == 1
              @html << "<pre><code>#{hover_string}</code></pre>"
            else
              @html << "<p>#{hover_sections.last}</p>"
              @html << "<pre><code>#{hover_sections.first}</code></pre>"
            end
          end
        end
        @html << "</div>"

        symbol.children.each do |child|
          visit_symbol(child)
        end
      end
    end
  end
end
