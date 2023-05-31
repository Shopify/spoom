# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Ruby < Base
        extend T::Sig

        ignore_method_names(
          "==",
          "extended",
          "included",
          "inherited",
          "method_added",
          "method_missing",
          "prepended",
          "respond_to_missing?",
          "to_s",
        )

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          case send.name
          when "send", "__send__", "try"
            reference_send_first_symbol_as_method(indexer, send)
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
      end
    end
  end
end
