# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rails < Base
        HELPER_FILE_RE = T.let(%r{app/helpers/.*\.rb$}, Regexp)

        ignore_constant_names("APP_PATH", "ENGINE_PATH", "ENGINE_ROOT")
        ignore_classes_if { |indexer, _definition| indexer.path.match?(HELPER_FILE_RE) }
        ignore_modules_if { |indexer, _definition| indexer.path.match?(HELPER_FILE_RE) }
      end
    end
  end
end
