# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class ActiveModel < Base
        ignore_subclasses_of(/^(::)?ActiveModel::EachValidator/)
        ignore_method_names("validate_each")
      end
    end
  end
end
