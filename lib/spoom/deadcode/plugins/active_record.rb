# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveRecord < Base
        ignore_subclasses_of(/^(::)?ActiveRecord::Migration/)

        ignore_method_names(
          "change",
          "down",
          "up",
          "table_name_prefix",
          "to_param",
        )
      end
    end
  end
end
