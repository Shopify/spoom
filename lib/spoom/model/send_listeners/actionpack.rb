# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class SendListener
      class ActionPack < SendListener
        CALLBACKS = T.let(
          [
            "after_action",
            "append_after_action",
            "append_around_action",
            "append_before_action",
            "around_action",
            "before_action",
            "prepend_after_action",
            "prepend_around_action",
            "prepend_before_action",
            "skip_after_action",
            "skip_around_action",
            "skip_before_action",
          ].freeze,
          T::Array[String],
        )

        sig { override.params(visitor: Model::ReferencesVisitor, send: Model::Send).void }
        def on_send(visitor, send)
          return unless send.recv.nil? && CALLBACKS.include?(send.name)

          arg = send.args.first
          case arg
          when Prism::SymbolNode
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
        end
      end
    end
  end
end
