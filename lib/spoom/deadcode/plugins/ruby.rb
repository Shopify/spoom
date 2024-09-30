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

        sig { override.params(send: Send).void }
        def on_send(send)
          case send.name
          when "const_defined?", "const_get", "const_source_location"
            reference_symbol_as_constant(send, T.must(send.args.first))
          when "send", "__send__", "try"
            arg = send.args.first
            @index.reference_method(arg.unescaped, send.location) if arg.is_a?(Prism::SymbolNode)
          when "alias_method"
            last_arg = send.args.last

            if last_arg.is_a?(Prism::SymbolNode) || last_arg.is_a?(Prism::StringNode)
              @index.reference_method(last_arg.unescaped, send.location)
            end
          when "method"
            arg = send.args.first
            @index.reference_method(arg.unescaped, send.location) if arg.is_a?(Prism::SymbolNode)
          end
        end

        private

        sig { params(send: Send, node: Prism::Node).void }
        def reference_symbol_as_constant(send, node)
          case node
          when Prism::SymbolNode
            @index.reference_constant(node.unescaped, send.location)
          when Prism::StringNode
            node.unescaped.split("::").each do |name|
              @index.reference_constant(name, send.location) unless name.empty?
            end
          end
        end
      end
    end
  end
end
