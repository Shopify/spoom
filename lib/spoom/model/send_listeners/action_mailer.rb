# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class SendListener
      class ActionMailer < SendListener
        sig { override.params(visitor: Model::ReferencesVisitor, send: Model::Send).void }
        def on_send(visitor, send)
          return unless send.recv.nil? && ActionPack::CALLBACKS.include?(send.name)

          send.each_arg(Prism::SymbolNode) do |arg|
            visitor.reference_method(arg.unescaped, arg)
          end
        end
      end
    end
  end
end
