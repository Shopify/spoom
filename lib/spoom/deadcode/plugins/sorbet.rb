# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Sorbet < Base
        extend T::Sig

        sig { override.params(symbol_def: Model::Constant, definition: Definition).void }
        def on_define_constant(symbol_def, definition)
          definition.ignored! if sorbet_type_member?(symbol_def) || sorbet_enum_constant?(symbol_def)
        end

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_method(indexer, definition)
          definition.ignored! if indexer.last_sig =~ /(override|overridable)/
        end

        private

        sig { params(symbol_def: Model::Constant).returns(T::Boolean) }
        def sorbet_type_member?(symbol_def)
          symbol_def.value.match?(/^(type_member|type_template)/)
        end

        sig { params(symbol_def: Model::Constant).returns(T::Boolean) }
        def sorbet_enum_constant?(symbol_def)
          owner = symbol_def.owner
          return false unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return false unless superclass_name

          superclass_name.match?(/^(::)?T::Enum$/)
        end
      end
    end
  end
end
