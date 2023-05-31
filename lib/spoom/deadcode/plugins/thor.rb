# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Thor < Base
        extend T::Sig

        THOR_CLASS_RE = T.let(/^(::)?Thor$/.freeze, Regexp)

        ignore_method_names("exit_on_failure?")
        ignore_methods_if { |indexer, _definition| thor_command?(indexer) }

        private

        sig { params(indexer: Indexer).returns(T::Boolean) }
        def thor_command?(indexer)
          return false if indexer.nesting_block

          THOR_CLASS_RE.match?(indexer.nesting_class_superclass_name)
        end
      end
    end
  end
end
