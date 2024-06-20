# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Sorbet < Base
        extend T::Sig

        sig { override.params(definition: Model::Constant).void }
        def on_define_constant(definition)
          @index.ignore(definition) if sorbet_type_member?(definition) || sorbet_enum_constant?(definition)
        end

        sig { override.params(definition: Model::Method).void }
        def on_define_method(definition)
          @index.ignore(definition) if definition.sigs.any? { |sig| sig.string =~ /(override|overridable)/ }
        end

        private

        sig { params(definition: Model::Constant).returns(T::Boolean) }
        def sorbet_type_member?(definition)
          definition.value.match?(/^(type_member|type_template)/)
        end

        sig { params(definition: Model::Constant).returns(T::Boolean) }
        def sorbet_enum_constant?(definition)
          owner = definition.owner
          return false unless owner.is_a?(Model::Class)

          subclass_of?(owner, "T::Enum")
        end
      end
    end
  end
end
