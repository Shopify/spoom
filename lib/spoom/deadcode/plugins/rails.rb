# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rails < Base
        ignore_constants_named("APP_PATH", "ENGINE_PATH", "ENGINE_ROOT")
      end
    end
  end
end
