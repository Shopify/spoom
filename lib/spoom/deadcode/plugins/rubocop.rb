# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rubocop < Base
        extend T::Sig

        RUBOCOP_CONSTANTS = T.let(
          Set.new([
            "MSG",
            "RESTRICT_ON_SEND",
          ].freeze),
          T::Set[String],
        )

        ignore_subclasses_of(/(::)?RuboCop::Cop::Cop/, /(::)?RuboCop::Cop::Base/)
        ignore_constants_if { |indexer, definition| rubocop_constant?(indexer, definition) }
        ignore_methods_if { |indexer, definition| rubocop_method?(indexer, definition) }

        private

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def rubocop_constant?(indexer, definition)
          ignored_subclass?(indexer.nesting_class_superclass_name) && RUBOCOP_CONSTANTS.include?(definition.name)
        end

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def rubocop_method?(indexer, definition)
          ignored_subclass?(indexer.nesting_class_superclass_name) && definition.name == "on_send"
        end
      end
    end
  end
end
