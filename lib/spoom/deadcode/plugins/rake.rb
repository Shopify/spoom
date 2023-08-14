# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rake < Base
        ignore_constant_names("APP_RAKEFILE")
      end
    end
  end
end
