# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Thor < Base
        extend T::Sig

        ignore_methods_named("exit_on_failure?")

        sig { override.params(symbol: Model::Method, definition: Definition).void }
        def on_define_method(symbol, definition)
          # TODO?
          # return if indexer.nesting_block # method defined in `no_commands do ... end`, we don't want to ignore it

          owner = symbol.owner
          return unless owner.is_a?(Model::Class)

          superclass_name = owner.superclass_name
          return unless superclass_name

          definition.ignored! if superclass_name =~ /^(::)?Thor$/
        end
      end
    end
  end
end
