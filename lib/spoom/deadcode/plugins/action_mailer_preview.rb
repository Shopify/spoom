# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionMailerPreview < Base
        extend T::Sig

        ignore_classes_inheriting_from("ActionMailer::Preview")

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_method(indexer, definition)
          definition.ignored! if indexer.nesting_class_superclass_name == "ActionMailer::Preview"
        end
      end
    end
  end
end
