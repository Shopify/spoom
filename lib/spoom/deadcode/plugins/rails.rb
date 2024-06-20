# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rails < Base
        extend T::Sig

        ignore_constants_named("APP_PATH", "ENGINE_PATH", "ENGINE_ROOT")

        sig { override.params(symbol_def: Model::Class, definition: Definition).void }
        def on_define_class(symbol_def, definition)
          definition.ignored! if file_is_helper?(symbol_def)
        end

        sig { override.params(symbol_def: Model::Module, definition: Definition).void }
        def on_define_module(symbol_def, definition)
          definition.ignored! if file_is_helper?(symbol_def)
        end

        private

        sig { params(symbol_def: Model::Namespace).returns(T::Boolean) }
        def file_is_helper?(symbol_def)
          symbol_def.location.file.match?(%r{app/helpers/.*\.rb$})
        end
      end
    end
  end
end
