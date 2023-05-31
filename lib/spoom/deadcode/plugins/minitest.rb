# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Minitest < Base
        ignore_method_names(
          "after_all",
          "around",
          "around_all",
          "before_all",
          "setup",
          "teardown",
        )
      end
    end
  end
end
