# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rubocop < Base
        extend T::Sig

        RUBOCOP_CONSTANTS = T.let(["MSG", "RESTRICT_ON_SEND"].to_set.freeze, T::Set[String])

        ignore_classes_inheriting_from(
          /^(::)?RuboCop::Cop::Cop$/,
          /^(::)?RuboCop::Cop::Base$/,
        )

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_constant(indexer, definition)
          definition.ignored! if rubocop_constant?(indexer, definition)
        end

        sig { override.params(symbol: Model::Method, definition: Definition).void }
        def on_define_method(symbol, definition)
          return unless symbol.name == "on_send"

          owner = symbol.owner
          return unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return unless superclass_name

          definition.ignored! if ignored_subclass?(superclass_name)
        end

        private

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def rubocop_constant?(indexer, definition)
          ignored_subclass?(indexer.nesting_class_superclass_name) && RUBOCOP_CONSTANTS.include?(definition.name)
        end
      end
    end
  end
end
