# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class IndexSet < Index
      extend T::Sig

      sig { void }
      def initialize
        super

        @names = T.let({}, T::Hash[String, T::Set[{ name: String, location: Location }]])
        @nodes = T.let({}, T::Hash[String, T::Array[[T::Set[{ name: String, location: Location }], { name: String, location: Location }]]])
      end

      sig { override.params(name: String).returns(T::Array[{ name: String, location: Location }]) }
      def [](name)
        @names[name]&.entries || []
      end

      sig { override.params(name: String, location: Location).void }
      def add_name(name, location)
        names = @names[name] ||= T.let(Set.new, T::Set[{ name: String, location: Location }])
        node = { name: name, location: location }

        names << node
        nodes = @nodes[location.path] ||= []
        nodes << [names, node]
      end

      sig { override.returns(T::Enumerable[String]) }
      def names
        @names.keys
      end

      sig { override.returns(T::Enumerable[{ name: String, location: Location }]) }
      def entries
        @names.values.map(&:to_a).flatten
      end

      sig { override.params(path: String).void }
      def delete_names_with_path(path)
        @nodes[path]&.each do |(list, node)|
          list.delete(node)
        end
      end
    end
  end
end
