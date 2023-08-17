# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Thor < Base
        extend T::Sig

        ignore_methods_named("exit_on_failure?")

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_method(indexer, definition)
          return if indexer.nesting_block # method defined in `no_commands do ... end`, we don't want to ignore it

          definition.ignored! if indexer.nesting_class_superclass_name =~ /^(::)?Thor$/
        end
      end
    end
  end
end
