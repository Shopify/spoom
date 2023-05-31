# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class GraphQL < Base
        extend T::Sig

        ignore_subclasses_of(
          "GraphQL::Schema::Enum",
          "GraphQL::Schema::Object",
          "GraphQL::Schema::Scalar",
          "GraphQL::Schema::Union",
        )

        ignore_method_names(
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
          return unless send.recv.nil?
          return unless send.name == "field"

          reference_send_first_symbol_as_method(indexer, send)

          send.args.each do |arg|
            next unless arg.is_a?(SyntaxTree::BareAssocHash)

            arg.assocs.each do |assoc|
              next unless assoc.is_a?(SyntaxTree::Assoc)
              next unless indexer.node_string(assoc.key) == "resolver_method:"

              resolver_method = indexer.symbol_string(T.must(assoc.value))
              indexer.reference_method(resolver_method, send.node)
            end
          end
        end
      end
    end
  end
end
