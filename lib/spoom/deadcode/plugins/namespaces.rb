# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Namespaces < Base
        extend T::Sig

        sig { override.params(definition: Model::Class).void }
        def on_define_class(definition)
          @index.ignore(definition) if used_as_namespace?(definition)
        end

        sig { override.params(definition: Model::Module).void }
        def on_define_module(definition)
          @index.ignore(definition) if used_as_namespace?(definition)
        end

        private

        sig { params(symbol_def: Model::Namespace).returns(T::Boolean) }
        def used_as_namespace?(symbol_def)
          symbol_def.children.any?
        end
      end
    end
  end
end
