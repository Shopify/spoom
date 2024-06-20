# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionMailerPreview < Base
        extend T::Sig

        ignore_classes_inheriting_from("ActionMailer::Preview")

        sig { override.params(symbol_def: Model::Method, definition: Definition).void }
        def on_define_method(symbol_def, definition)
          owner = symbol_def.owner
          return unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return unless superclass_name

          definition.ignored! if superclass_name == "ActionMailer::Preview"
        end
      end
    end
  end
end
