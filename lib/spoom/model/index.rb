# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class Index
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { abstract.params(name: String).returns(T::Enumerable[{ name: String, location: Location }]) }
      def [](name); end

      sig { abstract.params(name: String, location: Location).void }
      def add_name(name, location); end

      sig { abstract.returns(T::Enumerable[String]) }
      def names; end

      sig { abstract.returns(T::Enumerable[{ name: String, location: Location }]) }
      def entries; end

      sig { abstract.params(path: String).void }
      def delete_names_with_path(path); end
    end
  end
end
