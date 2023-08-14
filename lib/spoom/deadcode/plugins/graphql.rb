# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class GraphQL < Base
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
      end
    end
  end
end
