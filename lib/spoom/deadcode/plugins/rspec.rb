# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class RSpec < Base
        ignore_classes_if do |indexer, definition|
          indexer.path.match?(%r{spec/.*spec\.rb$}) && definition.name.match?(/Spec$/)
        end

        ignore_method_names(
          "after_setup",
          "after_teardown",
          "before_setup",
          "before_teardown",
        )
      end
    end
  end
end
