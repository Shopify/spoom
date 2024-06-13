# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Sorbet < Base
        extend T::Sig

        sig { override.params(symbol_def: Model::Constant, definition: Definition).void }
        def on_define_constant(symbol_def, definition)
          definition.ignored! if sorbet_type_member?(symbol_def)
          # TODO: || sorbet_enum_constant?(indexer, definition)
        end

        sig { override.params(symbol_def: Model::Method, definition: Definition).void }
        def on_define_method(symbol_def, definition)
          definition.ignored! if symbol_def.sigs.any? { |sig| sig.string =~ /(override|overridable)/ }
        end

        private

        sig { params(symbol_def: Model::Constant).returns(T::Boolean) }
        def sorbet_type_member?(symbol_def)
          symbol_def.value.match?(/^(type_member|type_template)/)
        end

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def sorbet_enum_constant?(indexer, definition)
          /^(::)?T::Enum$/.match?(indexer.nesting_class_superclass_name) && indexer.nesting_call&.name == :enums
        end
      end
    end
  end
end
