# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class IndexArray < Index
      extend T::Sig

      sig { void }
      def initialize
        super

        @names = T.let({}, T::Hash[String, T::Array[{ name: String, location: Location }]])
      end

      sig { override.params(name: String).returns(T::Array[{ name: String, location: Location }]) }
      def [](name)
        @names[name] || []
      end

      sig { override.params(name: String, location: Location).void }
      def add_name(name, location)
        names = @names[name] ||= []
        names << { name: name, location: location }
      end

      sig { override.returns(T::Enumerable[String]) }
      def names
        @names.keys
      end

      sig { override.returns(T::Enumerable[{ name: String, location: Location }]) }
      def entries
        @names.values.flatten
      end

      sig { override.params(path: String).void }
      def delete_names_with_path(path)
        @names.each do |_, names|
          names.delete_if { |n| n[:location].path == path }
        end
      end
    end
  end
end
