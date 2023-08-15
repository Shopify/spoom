# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionPack < Base
        ignore_classes_named(/Controller$/)
      end
    end
  end
end
