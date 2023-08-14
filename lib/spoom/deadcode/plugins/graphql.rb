# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class GraphQL < Base
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
