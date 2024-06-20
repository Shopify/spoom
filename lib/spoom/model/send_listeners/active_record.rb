# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class SendListener
      class ActiveRecord < SendListener
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

        sig { override.params(visitor: Model::ReferencesVisitor, send: Model::Send).void }
        def on_send(visitor, send)
          if send.recv.nil? && CALLBACKS.include?(send.name)
            send.each_arg(Prism::SymbolNode) do |arg|
              visitor.reference_method(arg.unescaped, arg)
            end
            return
          end

          return unless send.recv

          case send.name
          when *CRUD_METHODS
            send.each_arg_assoc do |key, _value|
              name = key.slice.delete_suffix(":")
              visitor.reference_method("#{name}=", key)
            end
          when *ARRAY_METHODS
            send.each_arg(Prism::ArrayNode) do |arg|
              arg.elements.each do |part|
                next unless part.is_a?(Prism::HashNode)

                part.elements.each do |assoc|
                  next unless assoc.is_a?(Prism::AssocNode)

                  key = assoc.key.slice.delete_suffix(":")
                  visitor.reference_method("#{key}=", arg)
                end
              end
            end
          end
        end
      end
    end
  end
end
