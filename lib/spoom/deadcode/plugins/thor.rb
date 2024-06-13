# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Thor < Base
        extend T::Sig

        ignore_methods_named("exit_on_failure?")

        sig { override.params(symbol_def: Model::Method, definition: Definition).void }
        def on_define_method(symbol_def, definition)
          owner = symbol_def.owner
          return unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return unless superclass_name

          definition.ignored! if superclass_name =~ /^(::)?Thor$/
        end
      end
    end
  end
end
