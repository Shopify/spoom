# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveRecord < Base
        extend T::Sig

        ignore_classes_inheriting_from(/^(::)?ActiveRecord::Migration/)

        ignore_methods_named(
          "change",
          "down",
          "up",
          "table_name_prefix",
          "to_param",
        )

        CALLBACKS = T.let(
          [
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
          ].freeze,
          T::Array[String],
        )

        CRUD_METHODS = T.let(
          [
            "assign_attributes",
            "create",
            "create!",
            "insert",
            "insert!",
            "new",
            "update",
            "update!",
            "upsert",
          ].freeze,
          T::Array[String],
        )

        ARRAY_METHODS = T.let(
          [
            "insert_all",
            "insert_all!",
            "upsert_all",
          ].freeze,
          T::Array[String],
        )

        sig { override.params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          if send.recv.nil? && CALLBACKS.include?(send.name)
            send.each_arg(SyntaxTree::SymbolLiteral) do |arg|
              indexer.reference_method(indexer.node_string(arg.value), send.node)
            end
            return
          end

          return unless send.recv

          case send.name
          when *CRUD_METHODS
            send.each_arg_assoc do |key, _value|
              key = indexer.symbol_string(key).delete_suffix(":")
              indexer.reference_method("#{key}=", send.node)
            end
          when *ARRAY_METHODS
            send.each_arg(SyntaxTree::ArrayLiteral) do |arg|
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
