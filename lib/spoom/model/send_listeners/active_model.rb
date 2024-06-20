# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class SendListener
      class ActiveModel < SendListener
        sig { override.params(visitor: Model::ReferencesVisitor, send: Model::Send).void }
        def on_send(visitor, send)
          return if send.recv

          case send.name
          when "attribute", "attributes"
            send.each_arg(Prism::SymbolNode) do |arg|
              visitor.reference_method(arg.unescaped, arg)
            end
          when "validate", "validates", "validates!", "validates_each"
            send.each_arg(Prism::SymbolNode) do |arg|
              visitor.reference_method(arg.unescaped, arg)
            end
            send.each_arg_assoc do |key, value|
              name = key.slice.delete_suffix(":")

              case name
              when "if", "unless"
                visitor.reference_method(value.slice.delete_prefix(":"), value) if value
              else
                visitor.reference_constant(camelize(name), key)
              end
            end
          when "validates_with"
            arg = send.args.first
            if arg.is_a?(Prism::SymbolNode)
              visitor.reference_constant(arg.unescaped, arg)
            end
          end
        end
      end
    end
  end
end
