# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Minitest < Base
        extend T::Sig

        ignore_classes_inheriting_from("Minitest::Test")

        MINITEST_METHODS = T.let(
          Set.new([
            "after_all",
            "around",
            "around_all",
            "before_all",
            "setup",
            "teardown",
          ]),
          T::Set[String],
        )

        sig { override.params(definition: Model::Method).void }
        def on_define_method(definition)
          return unless definition.name.start_with?("test_") || MINITEST_METHODS.include?(definition.name)

          owner = definition.owner
          return unless owner.is_a?(Model::Class)

          @index.ignore(definition) if ignored_subclass?(owner)
        end

        sig { override.params(send: Send).void }
        def on_send(send)
          case send.name
          when "test"
            return # this is a test method definition
          when "assert_predicate", "refute_predicate"
            name = send.args[1]&.slice
            return unless name

            @index.reference_method(name.delete_prefix(":"), send.location)
          end
        end
      end
    end
  end
end
