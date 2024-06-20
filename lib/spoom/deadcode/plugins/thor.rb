# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Thor < Base
        extend T::Sig

        ignore_methods_named("exit_on_failure?")

        sig { override.params(definition: Model::Method).void }
        def on_define_method(definition)
          owner = definition.owner
          return unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return unless superclass_name

          @index.ignore(definition) if superclass_name =~ /^(::)?Thor$/
        end
      end
    end
  end
end
