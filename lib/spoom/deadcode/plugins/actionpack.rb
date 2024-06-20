# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionPack < Base
        ignore_classes_inheriting_from("ApplicationController")

        sig { override.params(definition: Model::Method).void }
        def on_define_method(definition)
          owner = definition.owner
          return unless owner.is_a?(Model::Class)

          @index.ignore(definition) if ignored_subclass?(owner)
        end
      end
    end
  end
end
