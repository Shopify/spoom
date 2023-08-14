# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionPack < Base
        ignore_class_names(/Controller$/)
      end
    end
  end
end
