# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Ruby < Base
        ignore_methods_named(
          "==",
          "extended",
          "included",
          "inherited",
          "initialize",
          "method_added",
          "method_missing",
          "prepended",
          "respond_to_missing?",
          "to_s",
        )
      end
    end
  end
end
