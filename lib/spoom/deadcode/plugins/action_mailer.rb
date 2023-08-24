# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionMailer < Base
        extend T::Sig

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          return unless send.recv.nil? && ActionPack::CALLBACKS.include?(send.name)

          send.each_arg(SyntaxTree::SymbolLiteral) do |arg|
            indexer.reference_method(indexer.node_string(arg.value), send.node)
          end
        end
      end
    end
  end
end
