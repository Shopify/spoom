# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Ruby < Base
        extend T::Sig

        ignore_methods_named(
          "==",
          "extended",
          "included",
          "inherited",
          "initialize",
          "method_added",
          "method_missing",
          "prepended",
          "respond_to_missing?",
          "to_s",
        )

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          case send.name
          when "const_defined?", "const_get", "const_source_location"
            reference_symbol_as_constant(indexer, send, T.must(send.args.first))
          when "send", "__send__", "try"
            arg = send.args.first
            indexer.reference_method(indexer.node_string(arg.value), send.node) if arg.is_a?(SyntaxTree::SymbolLiteral)
          when "alias_method"
            last_arg = send.args.last

            name = case last_arg
            when SyntaxTree::SymbolLiteral
              indexer.node_string(last_arg.value)
            when SyntaxTree::StringLiteral
              last_arg.parts.map { |part| indexer.node_string(part) }.join
            end

            return unless name

            indexer.reference_method(name, send.node)
          end
        end

        private

        sig { params(indexer: Indexer, send: Send, node: SyntaxTree::Node).void }
        def reference_symbol_as_constant(indexer, send, node)
          case node
          when SyntaxTree::SymbolLiteral
            name = indexer.node_string(node.value)
            indexer.reference_constant(name, send.node)
          when SyntaxTree::StringLiteral
            string = T.must(indexer.node_string(node)[1..-2])
            string.split("::").each do |name|
              indexer.reference_constant(name, send.node) unless name.empty?
            end
          end
        end
      end
    end
  end
end
