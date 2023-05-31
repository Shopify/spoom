# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Minitest < Base
        ignore_class_names(/Test$/)

        ignore_method_names(
          "after_all",
          "around",
          "around_all",
          "before_all",
          "setup",
          "teardown",
        )

        ignore_methods_if do |indexer, definition|
          indexer.path.match?(%r{test/.*test\.rb$}) && definition.name.match?(/^test_/)
        end
      end
    end
  end
end
