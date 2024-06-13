# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rails < Base
        extend T::Sig

        ignore_constants_named("APP_PATH", "ENGINE_PATH", "ENGINE_ROOT")

        sig { override.params(symbol: Model::Class, definition: Definition).void }
        def on_define_class(symbol, definition)
          definition.ignored! if file_is_helper?(definition)
        end

        sig { override.params(symbol: Model::Module, definition: Definition).void }
        def on_define_module(symbol, definition)
          definition.ignored! if file_is_helper?(definition)
        end

        private

        sig { params(definition: Definition).returns(T::Boolean) }
        def file_is_helper?(definition)
          definition.location.file.match?(%r{app/helpers/.*\.rb$})
        end
      end
    end
  end
end
