# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Minitest < Base
        extend T::Sig

        ignore_classes_named(/Test$/)

        ignore_methods_named(
          "after_all",
          "around",
          "around_all",
          "before_all",
          "setup",
          "teardown",
        )

        sig { override.params(symbol: Model::Method, definition: Definition).void }
        def on_define_method(symbol, definition)
          file = definition.location.file
          definition.ignored! if file.match?(%r{test/.*test\.rb$}) && definition.name.match?(/^test_/)
        end
      end
    end
  end
end
