# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveRecord < Base
        ignore_classes_inheriting_from(/^(::)?ActiveRecord::Migration/)

        ignore_methods_named(
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
