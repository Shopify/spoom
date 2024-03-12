# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveSupport < Base
        ignore_classes_inheriting_from(/^(::)?ActiveSupport::TestCase$/)

        ignore_methods_named(
          "after_all",
          "after_setup",
          "after_teardown",
          "before_all",
          "before_setup",
          "before_teardown",
        )

        SETUP_AND_TEARDOWN_METHODS = T.let(["setup", "teardown"], T::Array[String])

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          return unless send.recv.nil? && SETUP_AND_TEARDOWN_METHODS.include?(send.name)

          send.each_arg(SyntaxTree::SymbolLiteral) do |arg|
            indexer.reference_method(indexer.node_string(arg.value), send.node)
          end
        end
      end
    end
  end
end
