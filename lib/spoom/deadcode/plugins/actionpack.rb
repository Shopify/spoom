# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionPack < Base
        extend T::Sig

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

        ignore_classes_named(/Controller$/)

        sig { override.params(symbol: Model::Method, definition: Definition).void }
        def on_define_method(symbol, definition)
          owner = symbol.owner
          return unless owner.is_a?(Model::Class)

          definition.ignored! if ignored_class_name?(owner.name)
        end

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          return unless send.recv.nil? && CALLBACKS.include?(send.name)

          arg = send.args.first
          case arg
          when Prism::SymbolNode
            indexer.reference_method(arg.unescaped, send.node)
          end

          send.each_arg_assoc do |key, value|
            key = key.slice.delete_suffix(":")

            case key
            when "if", "unless"
              indexer.reference_method(value.slice.delete_prefix(":"), send.node) if value
            else
              indexer.reference_constant(camelize(key), send.node)
            end
          end
        end
      end
    end
  end
end
