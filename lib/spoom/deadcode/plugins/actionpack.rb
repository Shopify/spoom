# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionPack < Base
        extend T::Sig

        ignore_class_names(/Controller$/)

        ignore_methods_if { |indexer, _definition| ignored_class_name?(indexer.nesting_class_name) }

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
          ],
          T::Array[String],
        )

        reference_send_symbols_as_methods(*T.unsafe(CALLBACKS))

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          super

          return if send.recv
          return unless CALLBACKS.include?(send.name)

          send.args.each do |arg|
            next unless arg.is_a?(SyntaxTree::BareAssocHash)

            arg.assocs.each do |assoc|
              next unless assoc.is_a?(SyntaxTree::Assoc)

              key = indexer.node_string(assoc.key)

              if key == "if:" || key == "unless:"
                call_name = indexer.symbol_string(T.must(assoc.value))
                indexer.reference_constant(call_name, send.node)
              else
                indexer.reference_constant(camelize(key), send.node)
              end
            end
          end
        end
      end
    end
  end
end
