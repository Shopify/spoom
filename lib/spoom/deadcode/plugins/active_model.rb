# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveModel < Base
        ignore_methods_named("validate_each")
      end
    end
  end
end
