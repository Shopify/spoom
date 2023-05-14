# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class IndexList < Index
      extend T::Sig

      sig { void }
      def initialize
        super

        @names = T.let({}, T::Hash[String, NodesList])
        @nodes = T.let({}, T::Hash[String, T::Array[IndexNode]])
      end

      sig { override.params(name: String).returns(T::Array[{ name: String, location: Location }]) }
      def [](name)
        @names[name]&.entries&.map { |location| { name: name, location: location } } || []
      end

      sig { override.params(name: String, location: Location).void }
      def add_name(name, location)
        names = @names[name] ||= NodesList.new
        node = names << { name: name, location: location }

        nodes = @nodes[location.path] ||= []
        nodes << node
      end

      sig { override.returns(T::Enumerable[String]) }
      def names
        @names.keys
      end

      sig { override.returns(T::Enumerable[{ name: String, location: Location }]) }
      def entries
        @names.map do |name, values|
          values.entries.map { |location| { name: name, location: location } }
        end.flatten
      end

      sig { override.params(path: String).void }
      def delete_names_with_path(path)
        @nodes[path]&.each do |node|
          node.delete!
        end
      end
    end

    class NodesList
      extend T::Sig

      sig { returns(T.nilable(IndexNode)) }
      attr_accessor :head, :tail

      sig { void }
      def initialize
        @head = T.let(nil, T.nilable(IndexNode))
        @tail = T.let(nil, T.nilable(IndexNode))
      end

      sig { params(entry: { name: String, location: Location }).returns(IndexNode) }
      def <<(entry)
        node = IndexNode.new(self, entry[:location])

        @head = node unless @head

        if @tail
          @tail.next_node = node
          @tail = node
        else
          @tail = node
        end

        node
      end

      sig { returns(T::Array[Location]) }
      def entries
        return [] unless @head

        entries = []

        node = T.let(@head, T.nilable(IndexNode))
        while node
          entries << node.location
          node = node.next_node
        end

        entries
      end
    end

    class IndexNode
      extend T::Sig

      sig { returns(Location) }
      attr_reader :location

      sig { returns(T.nilable(IndexNode)) }
      attr_accessor :prev_node, :next_node

      sig { params(list: NodesList, location: Location).void }
      def initialize(list, location)
        @list = list
        @location = location
        @prev_node = T.let(nil, T.nilable(IndexNode))
        @next_node = T.let(nil, T.nilable(IndexNode))
      end

      sig { void }
      def delete!
        prev_node&.next_node = next_node
        next_node&.prev_node = prev_node

        @list.head = @next_node if @list.head == self
        @list.tail = @prev_node if @list.tail == self
      end
    end
  end
end
