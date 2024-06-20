# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class SendListener
      class ActiveSupport < SendListener
        SETUP_AND_TEARDOWN_METHODS = T.let(["setup", "teardown"], T::Array[String])

        sig { override.params(visitor: Model::ReferencesVisitor, send: Model::Send).void }
        def on_send(visitor, send)
          return unless send.recv.nil? && SETUP_AND_TEARDOWN_METHODS.include?(send.name)

          send.each_arg(Prism::SymbolNode) do |arg|
            visitor.reference_method(T.must(arg.value), arg)
          end
        end
      end
    end
  end
end
