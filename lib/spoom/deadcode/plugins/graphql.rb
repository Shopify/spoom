# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class GraphQL < Base
        extend T::Sig

        ignore_classes_inheriting_from(
          /^(::)?GraphQL::Schema::Enum$/,
          /^(::)?GraphQL::Schema::Object$/,
          /^(::)?GraphQL::Schema::Scalar$/,
          /^(::)?GraphQL::Schema::Union$/,
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

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          return unless send.recv.nil? && send.name == "field"

          arg = send.args.first
          return unless arg.is_a?(SyntaxTree::SymbolLiteral)

          indexer.reference_method(indexer.node_string(arg.value), send.node)

          send.each_arg_assoc do |key, value|
            key = indexer.node_string(key).delete_suffix(":")
            next unless key == "resolver_method"
            next unless value

            indexer.reference_method(indexer.symbol_string(value), send.node)
          end
        end
      end
    end
  end
end
