# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveSupport < Base
        ignore_classes_inheriting_from("ActiveSupport::TestCase")

        ignore_methods_named(
          "after_all",
          "after_setup",
          "after_teardown",
          "before_all",
          "before_setup",
          "before_teardown",
        )

        SETUP_AND_TEARDOWN_METHODS = T.let(["setup", "teardown"], T::Array[String])
      end
    end
  end
end
