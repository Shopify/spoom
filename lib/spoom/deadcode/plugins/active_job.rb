# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveJob < Base
        ignore_classes_named("ApplicationJob")
        ignore_methods_named("perform", "build_enumerator", "each_iteration")

        CALLBACKS = [
          "after_enqueue",
          "after_perform",
          "around_enqueue",
          "around_perform",
          "before_enqueue",
          "before_perform",
        ].freeze

        # @override
        #: (Send send) -> void
        def on_send(send)
          return unless send.recv.nil? && CALLBACKS.include?(send.name)

          send.each_arg(Prism::SymbolNode) do |arg|
            @index.reference_method(arg.unescaped, send.location)
          end
        end
      end
    end
  end
end
