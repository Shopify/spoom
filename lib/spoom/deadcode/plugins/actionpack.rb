# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionPack < Base
        extend T::Sig

        ignore_classes_named(/Controller$/)

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_method(indexer, definition)
          definition.ignored! if ignored_class_name?(indexer.nesting_class_name)
        end
      end
    end
  end
end
