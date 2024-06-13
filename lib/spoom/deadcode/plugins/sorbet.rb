# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Sorbet < Base
        extend T::Sig

        sig { override.params(symbol: Model::Constant, definition: Definition).void }
        def on_define_constant(symbol, definition)
          # TODO: definition.ignored! if sorbet_type_member?(indexer, definition) || sorbet_enum_constant?(indexer, definition)
        end

        sig { override.params(symbol: Model::Method, definition: Definition).void }
        def on_define_method(symbol, definition)
          # TODO: sigs
          # definition.ignored! if indexer.last_sig =~ /(override|overridable)/
        end

        private

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def sorbet_type_member?(indexer, definition)
          assign = indexer.nesting_node(Prism::ConstantWriteNode)
          return false unless assign

          value = assign.value
          return false unless value.is_a?(Prism::CallNode)

          value.name == :type_member || value.name == :type_template
        end

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def sorbet_enum_constant?(indexer, definition)
          /^(::)?T::Enum$/.match?(indexer.nesting_class_superclass_name) && indexer.nesting_call&.name == :enums
        end
      end
    end
  end
end
