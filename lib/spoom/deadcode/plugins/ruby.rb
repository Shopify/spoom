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
            indexer.reference_method(arg.unescaped, send.node) if arg.is_a?(Prism::SymbolNode)
          when "alias_method"
            last_arg = send.args.last

            if last_arg.is_a?(Prism::SymbolNode) || last_arg.is_a?(Prism::StringNode)
              indexer.reference_method(last_arg.unescaped, send.node)
            end
          end
        end

        private

        sig { params(indexer: Indexer, send: Send, node: Prism::Node).void }
        def reference_symbol_as_constant(indexer, send, node)
          case node
          when Prism::SymbolNode
            indexer.reference_constant(node.unescaped, send.node)
          when Prism::StringNode
            node.unescaped.split("::").each do |name|
              indexer.reference_constant(name, send.node) unless name.empty?
            end
          end
        end
      end
    end
  end
end
