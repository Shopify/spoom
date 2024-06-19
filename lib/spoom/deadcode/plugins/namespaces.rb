# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Namespaces < Base
        extend T::Sig

        sig { override.params(symbol_def: Model::Class, definition: Definition).void }
        def on_define_class(symbol_def, definition)
          definition.ignored! if used_as_namespace?(symbol_def)
        end

        sig { override.params(symbol_def: Model::Module, definition: Definition).void }
        def on_define_module(symbol_def, definition)
          definition.ignored! if used_as_namespace?(symbol_def)
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
