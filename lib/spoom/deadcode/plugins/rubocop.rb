# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Rubocop < Base
        ignore_classes_inheriting_from(
          /^(::)?RuboCop::Cop::Cop$/,
          /^(::)?RuboCop::Cop::Base$/,
        )
      end
    end
  end
end
