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

        # @override
        #: (Send send) -> void
        def on_send(send)
          return if send.recv

          case send.name
          when "field"
            arg = send.args.first
            return unless arg.is_a?(Prism::SymbolNode)

            @index.reference_method(arg.unescaped, send.location)

            send.each_arg_assoc do |key, value|
              key = key.slice.delete_suffix(":")
              next unless key == "resolver_method" || key == "method"
              next unless value

              @index.reference_method(value.slice.delete_prefix(":"), send.location)
            end
          when "argument"
            send.each_arg_assoc do |key, value|
              key = key.slice.delete_suffix(":")
              next unless key == "prepare" || key == "method"
              next unless value

              @index.reference_method(value.slice.delete_prefix(":"), send.location)
            end
          when "builds"
            arg = send.args.first
            return unless arg.is_a?(Prism::SymbolNode)

            @index.reference_method("build_#{arg.unescaped}", send.location)
          end
        end
      end
    end
  end
end
