# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class SendListener
      class GraphQL < SendListener
        sig { override.params(visitor: Model::ReferencesVisitor, send: Model::Send).void }
        def on_send(visitor, send)
          return unless send.recv.nil? && send.name == "field"

          arg = send.args.first
          return unless arg.is_a?(Prism::SymbolNode)

          visitor.reference_method(arg.unescaped, arg)

          send.each_arg_assoc do |key, value|
            name = key.slice.delete_suffix(":")
            next unless name == "resolver_method"
            next unless value

            visitor.reference_method(value.slice.delete_prefix(":"), value)
          end
        end
      end
    end
  end
end
