# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveModel < Base
        ignore_classes_inheriting_from("ActiveModel::EachValidator")
        ignore_methods_named("validate_each", "persisted?")

        # @override
        #: (Send send) -> void
        def on_send(send)
          return if send.recv

          case send.name
          when "attribute", "attributes"
            send.each_arg(Prism::SymbolNode) do |arg|
              @index.reference_method(arg.unescaped, send.location)
            end
          when "validate", "validates", "validates!", "validates_each"
            send.each_arg(Prism::SymbolNode) do |arg|
              @index.reference_method(arg.unescaped, send.location)
            end
            send.each_arg_assoc do |key, value|
              next unless key.is_a?(Prism::SymbolNode)

              key = key.unescaped

              case key
              when "if", "unless"
                @index.reference_method(value.unescaped, send.location) if value.is_a?(Prism::SymbolNode)
              else
                @index.reference_constant(camelize(key), send.location)

                if value.is_a?(Prism::HashNode)
                  reference_nested_symbol_options(value, send.location)
                end
              end
            end
          when "validates_with"
            arg = send.args.first
            if arg.is_a?(Prism::SymbolNode)
              @index.reference_constant(arg.unescaped, send.location)
            end
          end
        end

        private

        NESTED_METHOD_REFERENCE_KEYS = T.let(
          [
            "if",
            "unless",
            "in",
            "with",
            "less_than",
            "greater_than",
            "less_than_or_equal_to",
            "greater_than_or_equal_to",
            "equal_to",
            "other_than",
          ].freeze,
          T::Array[String],
        )

        #: (Prism::HashNode hash_node, Location location) -> void
        def reference_nested_symbol_options(hash_node, location)
          hash_node.elements.each do |assoc|
            next unless assoc.is_a?(Prism::AssocNode)

            key = assoc.key
            next unless key.is_a?(Prism::SymbolNode)

            nested_key = key.unescaped
            next unless NESTED_METHOD_REFERENCE_KEYS.include?(nested_key)

            value = assoc.value
            next unless value.is_a?(Prism::SymbolNode)

            @index.reference_method(value.unescaped, location)
          end
        end
      end
    end
  end
end
