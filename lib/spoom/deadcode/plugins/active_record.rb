# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveRecord < Base
        extend T::Sig

        ignore_subclasses_of(/^(::)?ActiveRecord::Migration/)

        ignore_method_names(
          "change",
          "down",
          "up",
          "table_name_prefix",
          "to_param",
        )

        reference_send_symbols_as_methods(
          "after_commit",
          "after_create_commit",
          "after_create",
          "after_destroy_commit",
          "after_destroy",
          "after_find",
          "after_initialize",
          "after_rollback",
          "after_save_commit",
          "after_save",
          "after_touch",
          "after_update_commit",
          "after_update",
          "after_validation",
          "around_create",
          "around_destroy",
          "around_save",
          "around_update",
          "before_create",
          "before_destroy",
          "before_save",
          "before_update",
          "before_validation",
        )

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          super

          return unless send.recv

          case send.name
          when "assign_attributes", "create", "create!", "insert", "insert!", "new", "update", "update!", "upsert"
            send.args.each do |arg|
              next unless arg.is_a?(SyntaxTree::BareAssocHash) || arg.is_a?(SyntaxTree::HashLiteral)

              arg.assocs.each do |assoc|
                next unless assoc.is_a?(SyntaxTree::Assoc)

                key = indexer.symbol_string(assoc.key).delete_suffix(":")
                indexer.reference_method("#{key}=", send.node)
              end
            end
          when "insert_all", "insert_all!", "upsert_all"
            send.args.each do |arg|
              next unless arg.is_a?(SyntaxTree::ArrayLiteral)

              args = arg.contents
              next unless args.is_a?(SyntaxTree::Args)

              args.parts.each do |part|
                next unless part.is_a?(SyntaxTree::HashLiteral)

                part.assocs.each do |assoc|
                  next unless assoc.is_a?(SyntaxTree::Assoc)

                  key = indexer.symbol_string(assoc.key).delete_suffix(":")
                  indexer.reference_method("#{key}=", send.node)
                end
              end
            end
          end
        end
      end
    end
  end
end
