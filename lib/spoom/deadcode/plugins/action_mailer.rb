# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActionMailer < Base
        reference_send_symbols_as_methods("after_action", "around_action", "before_action")
      end
    end
  end
end
