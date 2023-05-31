# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    # A reference is a call to a method or a constant
    class Reference < T::Struct
      extend T::Sig

      class Kind < T::Enum
        enums do
          Constant = new
          Method = new
        end
      end

      const :kind, Kind
      const :name, String
      const :location, Location

      # Kind

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
