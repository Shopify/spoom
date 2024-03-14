# typed: strict
# frozen_string_literal: true

module Spoom
  class Poset
    extend T::Sig
    extend T::Generic

    E = type_member { { upper: Object } }

    sig { void }
    def initialize
      @nodes = T.let({}, T::Hash[E, Element[E]])
    end

    sig { params(value: E).returns(Element[E]) }
    def [](value)
      poe = @nodes[value]
      raise unless poe

      poe
    end

    sig { params(value: E).returns(Element[E]) }
    def add_node(value)
      poe = @nodes[value]
      return poe if poe

      @nodes[value] = Element[E].new(self, value)
    end

    sig { params(from: E, to: E).void }
    def add_direct_edge(from, to)
      from_poe = add_node(from)
      to_poe = add_node(to)

      # We already added this direct edge, which means we already computed the transitive closure
      return if from_poe.parents.include?(to)

      # Add the direct edges
      from_poe.dtos << to_poe
      to_poe.dfroms << from_poe

      # Compute the transitive closure

      from_poe.tos << to_poe
      from_poe.froms.each do |child_poe|
        child_poe.tos << to_poe
        to_poe.froms << child_poe

        to_poe.tos.each do |parent_poe|
          parent_poe.froms << child_poe
          child_poe.tos << parent_poe
        end
      end

      to_poe.froms << from_poe
      to_poe.tos.each do |parent_poe|
        parent_poe.froms << from_poe
        from_poe.tos << parent_poe

        from_poe.froms.each do |child_poe|
          child_poe.tos << parent_poe
          parent_poe.froms << child_poe
        end
      end
    end

    sig { params(from: E, to: E).returns(T::Boolean) }
    def edge?(from, to)
      from_poe = @nodes[from]
      return false unless from_poe

      from_poe.ancestors.include?(to)
    end

    sig { params(from: E, to: E).returns(T::Boolean) }
    def direct_edge?(from, to)
      self[from].parents.include?(to)
    end

    sig { params(value: E).returns(T::Boolean) }
    def node?(value)
      @nodes.key?(value)
    end

    # sig { params(elements: T::Array[E]).returns(T::Array[E]) }
    # def linearize(elements)
    #   elements.sort do |a, b|
    #     a_poe = self[a]
    #     b_poe = self[b]
    #     res = a_poe.tos.length <=> b_poe.tos.length
    #     next res if res != 0

    #     a_poe.rank <=> b_poe.rank
    #   end
    # end

    sig { params(direct: T::Boolean, transitive: T::Boolean).void }
    def show_dot(direct: true, transitive: true)
      Open3.popen3("xdot -") do |stdin, _stdout, _stderr, _thread|
        stdin.write(to_dot(direct: direct, transitive: transitive))
        stdin.close
      end
    end

    sig { params(direct: T::Boolean, transitive: T::Boolean).returns(String) }
    def to_dot(direct: true, transitive: true)
      dot = +"digraph {\n"
      dot << "  rankdir=BT;\n"
      @nodes.each do |element, poe|
        dot << "  \"#{element}\";\n"
        if direct
          poe.parents.each do |to|
            dot << "  \"#{element}\" -> \"#{to}\";\n"
          end
        end
        if transitive # rubocop:disable Style/Next
          poe.ancestors.each do |ancestor|
            dot << "  \"#{element}\" -> \"#{ancestor}\" [style=dotted];\n"
          end
        end
      end
      dot << "}\n"
    end

    class Element
      extend T::Sig
      extend T::Generic

      # TODO: implement comparable?

      E = type_member { { upper: Object } }

      sig { returns(E) }
      attr_reader :value

      sig { returns(T::Set[Element[E]]) }
      attr_reader :dtos, :tos, :dfroms, :froms

      sig { params(poset: Poset[E], value: E).void }
      def initialize(poset, value)
        @poset = poset
        @value = value
        @dtos = T.let(Set.new, T::Set[Element[E]])
        @tos = T.let(Set.new, T::Set[Element[E]])
        @dfroms = T.let(Set.new, T::Set[Element[E]])
        @froms = T.let(Set.new, T::Set[Element[E]])
      end

      sig { params(other: E).returns(T::Boolean) }
      def <=(other)
        ancestors.include?(other)
      end

      sig { params(other: E).returns(T::Boolean) }
      def <(other)
        other != @value && ancestors.include?(other)
      end

      sig { returns(T::Array[E]) }
      def parents
        @dtos.map(&:value)
      end

      sig { returns(T::Array[E]) }
      def ancestors
        @tos.map(&:value)
      end

      sig { returns(T::Array[E]) }
      def children
        @dfroms.map(&:value)
      end

      sig { returns(T::Array[E]) }
      def descendants
        @froms.map(&:value)
      end
    end
  end
end
