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

        sig { override.params(symbol_def: Model::Method, definition: Definition).void }
        def on_define_method(symbol_def, definition)
          file = symbol_def.location.file
          definition.ignored! if file.match?(%r{test/.*test\.rb$}) && symbol_def.name.match?(/^test_/)
        end
      end
    end
  end
end
