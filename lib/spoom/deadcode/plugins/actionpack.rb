# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionPack < Base
        ignore_class_names(/Controller$/)

        ignore_methods_if { |indexer, _definition| ignored_class_name?(indexer.nesting_class_name) }
      end
    end
  end
end
