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

        CALLBACKS = [
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
        ].freeze #: Array[String]

        CALLBACK_CONDITIONS = [
          "if",
          "unless",
        ].freeze #: Array[String]

        CRUD_METHODS = [
          "assign_attributes",
          "create",
          "create!",
          "insert",
          "insert!",
          "new",
          "update",
          "update!",
          "upsert",
        ].freeze #: Array[String]

        ARRAY_METHODS = [
          "insert_all",
          "insert_all!",
          "upsert_all",
        ].freeze #: Array[String]

        # @override
        #: (Send send) -> void
        def on_send(send)
          if send.recv.nil? && CALLBACKS.include?(send.name)
            # Process direct symbol arguments
            send.each_arg(Prism::SymbolNode) do |arg|
              @index.reference_method(arg.unescaped, send.location)
            end

            # Process hash arguments for conditions like if: :method_name
            send.each_arg_assoc do |key, value|
              key = key.slice.delete_suffix(":")

              case key
              when *CALLBACK_CONDITIONS
                if value&.is_a?(Prism::SymbolNode)
                  @index.reference_method(value.unescaped, send.location)
                end
              end
            end

            return
          end

          return unless send.recv

          case send.name
          when *CRUD_METHODS
            send.each_arg_assoc do |key, _value|
              key = key.slice.delete_suffix(":")
              @index.reference_method("#{key}=", send.location)
            end
          when *ARRAY_METHODS
            send.each_arg(Prism::ArrayNode) do |arg|
              arg.elements.each do |part|
                next unless part.is_a?(Prism::HashNode)

                part.elements.each do |assoc|
                  next unless assoc.is_a?(Prism::AssocNode)

                  key = assoc.key.slice.delete_suffix(":")
                  @index.reference_method("#{key}=", send.location)
                end
              end
            end
          end
        end
      end
    end
  end
end
