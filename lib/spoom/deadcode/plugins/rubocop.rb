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

        sig { override.params(symbol_def: Model::Constant, definition: Definition).void }
        def on_define_constant(symbol_def, definition)
          owner = symbol_def.owner
          return false unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return false unless superclass_name

          definition.ignored! if ignored_subclass?(superclass_name) && RUBOCOP_CONSTANTS.include?(symbol_def.name)
        end

        sig { override.params(symbol_def: Model::Method, definition: Definition).void }
        def on_define_method(symbol_def, definition)
          return unless symbol_def.name == "on_send"

          owner = symbol_def.owner
          return unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return unless superclass_name

          definition.ignored! if ignored_subclass?(superclass_name)
        end
      end
    end
  end
end
