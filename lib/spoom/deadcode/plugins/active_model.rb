# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveModel < Base
        extend T::Sig

        ignore_subclasses_of(/^(::)?ActiveModel::EachValidator/)
        ignore_method_names("validate_each")
        reference_send_symbols_as_methods("attribute", "attributes", "validate")

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          super

          return if send.recv

          case send.name
          when "validates_with"
            reference_send_first_symbol_as_constant(indexer, send)
          when "attribute", "validates", "validates!", "validates_each"
            send.args.each do |arg|
              next unless arg.is_a?(SyntaxTree::BareAssocHash)

              arg.assocs.each do |assoc|
                next unless assoc.is_a?(SyntaxTree::Assoc)

                key = indexer.node_string(assoc.key)

                if key == "if:" || key == "unless:"
                  call_name = indexer.symbol_string(T.must(assoc.value))
                  indexer.reference_constant(call_name, send.node)
                else
                  indexer.reference_constant(camelize(key), send.node)
                end
              end
            end
          end
        end
      end
    end
  end
end
