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
          definition.ignored! if definition.location.file.match?(%r{app/helpers/.*\.rb$})
        end

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_module(indexer, definition)
          definition.ignored! if file_is_helper?(indexer)
        end

        private

        sig { params(indexer: Indexer).returns(T::Boolean) }
        def file_is_helper?(indexer)
          indexer.path.match?(%r{app/helpers/.*\.rb$})
        end
      end
    end
  end
end
