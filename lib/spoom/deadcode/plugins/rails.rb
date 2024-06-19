# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rails < Base
        extend T::Sig

        ignore_constants_named("APP_PATH", "ENGINE_PATH", "ENGINE_ROOT")

        sig { override.params(definition: Model::Class).void }
        def on_define_class(definition)
          @index.ignore(definition) if file_is_helper?(definition)
        end

        sig { override.params(definition: Model::Module).void }
        def on_define_module(definition)
          @index.ignore(definition) if file_is_helper?(definition)
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
