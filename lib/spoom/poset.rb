# typed: strict
# frozen_string_literal: true

module Spoom
  # A Poset is a set of elements with a partial order relation.
  #
  # The partial order relation is a binary relation that is reflexive, antisymmetric, and transitive.
  # It can be used to represent a hierarchy of classes or modules, the dependencies between gems, etc.
  class Poset
    extend T::Sig
    extend T::Generic

    class Error < Spoom::Error; end

    E = type_member { { upper: Object } }

    sig { void }
    def initialize
      @elements = T.let({}, T::Hash[E, Element[E]])
    end

    # Get the POSet element for a given value
    #
    # Raises if the element is not found
    sig { params(value: E).returns(Element[E]) }
    def [](value)
      element = @elements[value]
      raise Error, "POSet::Element not found for #{value}" unless element

      element
    end

    # Add an element to the POSet
    sig { params(value: E).returns(Element[E]) }
    def add_element(value)
      element = @elements[value]
      return element if element

      @elements[value] = Element[E].new(value)
    end

    # Is the given value a element in the POSet?
    sig { params(value: E).returns(T::Boolean) }
    def element?(value)
      @elements.key?(value)
    end

    # Add a direct edge from one element to another
    #
    # Transitive edges (transitive closure) are automatically computed.
    # Adds the elements if they don't exist.
    # If the direct edge already exists, nothing is done.
    sig { params(from: E, to: E).void }
    def add_direct_edge(from, to)
      from_element = add_element(from)
      to_element = add_element(to)

      # We already added this direct edge, which means we already computed the transitive closure
      return if from_element.parents.include?(to)

      # Add the direct edges
      from_element.dtos << to_element
      to_element.dfroms << from_element

      # Compute the transitive closure

      from_element.tos << to_element
      from_element.froms.each do |child_element|
        child_element.tos << to_element
        to_element.froms << child_element

        to_element.tos.each do |parent_element|
          parent_element.froms << child_element
          child_element.tos << parent_element
        end
      end

      to_element.froms << from_element
      to_element.tos.each do |parent_element|
        parent_element.froms << from_element
        from_element.tos << parent_element

        from_element.froms.each do |child_element|
          child_element.tos << parent_element
          parent_element.froms << child_element
        end
      end
    end

    # Is there an edge (direct or indirect) from `from` to `to`?
    sig { params(from: E, to: E).returns(T::Boolean) }
    def edge?(from, to)
      from_element = @elements[from]
      return false unless from_element

      from_element.ancestors.include?(to)
    end

    # Is there a direct edge from `from` to `to`?
    sig { params(from: E, to: E).returns(T::Boolean) }
    def direct_edge?(from, to)
      self[from].parents.include?(to)
    end

    # Show the POSet as a DOT graph using xdot (used for debugging)
    sig { params(direct: T::Boolean, transitive: T::Boolean).void }
    def show_dot(direct: true, transitive: true)
      Open3.popen3("xdot -") do |stdin, _stdout, _stderr, _thread|
        stdin.write(to_dot(direct: direct, transitive: transitive))
        stdin.close
      end
    end

    # Return the POSet as a DOT graph
    sig { params(direct: T::Boolean, transitive: T::Boolean).returns(String) }
    def to_dot(direct: true, transitive: true)
      dot = +"digraph {\n"
      dot << "  rankdir=BT;\n"
      @elements.each do |value, element|
        dot << "  \"#{value}\";\n"
        if direct
          element.parents.each do |to|
            dot << "  \"#{value}\" -> \"#{to}\";\n"
          end
        end
        if transitive # rubocop:disable Style/Next
          element.ancestors.each do |ancestor|
            dot << "  \"#{value}\" -> \"#{ancestor}\" [style=dotted];\n"
          end
        end
      end
      dot << "}\n"
    end

    # An element in a POSet
    class Element
      extend T::Sig
      extend T::Generic
      include Comparable

      E = type_member { { upper: Object } }

      # The value held by this element
      sig { returns(E) }
      attr_reader :value

      # Edges (direct and indirect) from this element to other elements in the same POSet
      sig { returns(T::Set[Element[E]]) }
      attr_reader :dtos, :tos, :dfroms, :froms

      sig { params(value: E).void }
      def initialize(value)
        @value = value
        @dtos = T.let(Set.new, T::Set[Element[E]])
        @tos = T.let(Set.new, T::Set[Element[E]])
        @dfroms = T.let(Set.new, T::Set[Element[E]])
        @froms = T.let(Set.new, T::Set[Element[E]])
      end

      sig { params(other: T.untyped).returns(T.nilable(Integer)) }
      def <=>(other)
        return unless other.is_a?(Element)
        return 0 if self == other

        if tos.include?(other)
          -1
        elsif froms.include?(other)
          1
        end
      end

      # Direct parents of this element
      sig { returns(T::Array[E]) }
      def parents
        @dtos.map(&:value)
      end

      # Direct and indirect ancestors of this element
      sig { returns(T::Array[E]) }
      def ancestors
        @tos.map(&:value)
      end

      # Direct children of this element
      sig { returns(T::Array[E]) }
      def children
        @dfroms.map(&:value)
      end

      # Direct and indirect descendants of this element
      sig { returns(T::Array[E]) }
      def descendants
        @froms.map(&:value)
      end
    end
  end
end
