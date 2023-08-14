# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Thor < Base
        ignore_method_names("exit_on_failure?")
      end
    end
  end
end
