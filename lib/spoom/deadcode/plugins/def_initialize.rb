# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class DefInitialize < Base
        ignore_method_names("initialize")
      end
    end
  end
end
