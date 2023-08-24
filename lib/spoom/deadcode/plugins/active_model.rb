# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveModel < Base
        extend T::Sig

        ignore_classes_inheriting_from(/^(::)?ActiveModel::EachValidator$/)
        ignore_methods_named("validate_each")

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          return if send.recv

          case send.name
          when "attribute", "attributes"
            send.each_arg(SyntaxTree::SymbolLiteral) do |arg|
              indexer.reference_method(indexer.node_string(arg.value), send.node)
            end
          when "validate", "validates", "validates!", "validates_each"
            send.each_arg(SyntaxTree::SymbolLiteral) do |arg|
              indexer.reference_method(indexer.node_string(arg.value), send.node)
            end
            send.each_arg_assoc do |key, value|
              key = indexer.node_string(key).delete_suffix(":")

              case key
              when "if", "unless"
                indexer.reference_method(indexer.symbol_string(value), send.node) if value
              else
                indexer.reference_constant(camelize(key), send.node)
              end
            end
          when "validates_with"
            arg = send.args.first
            if arg.is_a?(SyntaxTree::SymbolLiteral)
              indexer.reference_constant(indexer.node_string(arg.value), send.node)
            end
          end
        end
      end
    end
  end
end
