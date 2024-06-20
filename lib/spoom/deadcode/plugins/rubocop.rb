# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rubocop < Base
        extend T::Sig

        RUBOCOP_CONSTANTS = T.let(["MSG", "RESTRICT_ON_SEND"].to_set.freeze, T::Set[String])

        ignore_classes_inheriting_from(
          "RuboCop::Cop::Cop",
          "RuboCop::Cop::Base",
        )

        sig { override.params(definition: Model::Constant).void }
        def on_define_constant(definition)
          owner = definition.owner
          return false unless owner.is_a?(Model::Class)

          @index.ignore(definition) if ignored_subclass?(owner) && RUBOCOP_CONSTANTS.include?(definition.name)
        end

        sig { override.params(definition: Model::Method).void }
        def on_define_method(definition)
          return unless definition.name == "on_send"

          owner = definition.owner
          return unless owner.is_a?(Model::Class)

          @index.ignore(definition) if ignored_subclass?(owner)
        end
      end
    end
  end
end
