# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    # A reference to something that looks like a constant or a method
    #
    # Constants could be classes, modules, or actual constants.
    # Methods could be accessors, instance or class methods, aliases, etc.
    class Reference < T::Struct
      extend T::Sig

      class Kind < T::Enum
        enums do
          Constant = new("constant")
          Method = new("method")
        end
      end

      const :kind, Kind
      const :name, String
      const :location, Spoom::Location

      sig { returns(T::Boolean) }
      def constant?
        kind == Kind::Constant
      end

      sig { returns(T::Boolean) }
      def method?
        kind == Kind::Method
      end
    end
  end
end
