# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class GraphQL < Base
        ignore_classes_inheriting_from(
          "GraphQL::Schema::Enum",
          "GraphQL::Schema::Object",
          "GraphQL::Schema::Scalar",
          "GraphQL::Schema::Union",
        )

        ignore_methods_named(
          "coerce_input",
          "coerce_result",
          "graphql_name",
          "resolve",
          "resolve_type",
          "subscribed",
          "unsubscribed",
        )

        FIELD_SYMBOL_OPTION_KEYS = ["resolver_method", "method"].freeze #: Array[String]
        ARGUMENT_SYMBOL_OPTION_KEYS = ["prepare", "method"].freeze #: Array[String]

        # @override
        #: (Send send) -> void
        def on_send(send)
          return unless send.recv.nil?

          case send.name
          when "field"
            on_field(send)
          when "argument"
            on_argument(send)
          when "builds"
            on_builds(send)
          end
        end

        private

        #: (Send send) -> void
        def on_field(send)
          arg = send.args.first
          return unless arg.is_a?(Prism::SymbolNode)

          @index.reference_method(arg.unescaped, send.location)

          send.each_arg_assoc do |key, value|
            next unless key.is_a?(Prism::SymbolNode)
            next unless FIELD_SYMBOL_OPTION_KEYS.include?(key.unescaped)
            next unless value.is_a?(Prism::SymbolNode)

            @index.reference_method(value.unescaped, send.location)
          end
        end

        #: (Send send) -> void
        def on_argument(send)
          send.each_arg_assoc do |key, value|
            next unless key.is_a?(Prism::SymbolNode)
            next unless ARGUMENT_SYMBOL_OPTION_KEYS.include?(key.unescaped)
            next unless value.is_a?(Prism::SymbolNode)

            @index.reference_method(value.unescaped, send.location)
          end
        end

        #: (Send send) -> void
        def on_builds(send)
          send.args.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            @index.reference_method("build_#{arg.unescaped}", send.location)
          end
        end
      end
    end
  end
end
