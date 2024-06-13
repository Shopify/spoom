# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class PosetTest < Minitest::Test
    def test_empty
      poset = Poset[String].new

      refute(poset.node?("A"))
      refute(poset.edge?("A", "B"))
    end

    def test_raises_if_element_not_found
      poset = Poset[String].new

      assert_raises(Poset::Error) { poset["A"] }
    end

    def test_add_node
      poset = Poset[String].new

      poset.add_node("A")
      assert(poset.node?("A"))
      refute(poset.node?("B"))

      poset.add_node("B")
      assert(poset.node?("A"))
      assert(poset.node?("B"))
    end

    def test_add_edge_also_adds_nodes
      poset = Poset[String].new
      poset.add_direct_edge("A", "B")

      assert(poset.node?("A"))
      assert(poset.node?("B"))
    end

    def test_add_edge_creates_direct_edge
      poset = Poset[String].new

      poset.add_direct_edge("A", "B")
      assert(poset.direct_edge?("A", "B"))

      poset.add_direct_edge("B", "C")
      assert(poset.direct_edge?("B", "C"))

      refute(poset.direct_edge?("A", "C"))
    end

    def test_add_edge_creates_transitive_edge
      poset = Poset[String].new

      poset.add_direct_edge("A", "B")
      assert(poset.edge?("A", "B"))

      poset.add_direct_edge("B", "C")
      assert(poset.edge?("B", "C"))
      assert(poset.edge?("A", "C"))
    end

    def test_add_edge_not_reflexive
      poset = Poset[String].new
      poset.add_direct_edge("A", "B")

      assert(poset.direct_edge?("A", "B"))
      refute(poset.direct_edge?("B", "A"))

      assert(poset.edge?("A", "B"))
      refute(poset.edge?("B", "A"))
    end

    def test_update_edges
      poset = Poset[String].new

      poset.add_direct_edge("A", "B")
      assert(poset.edge?("A", "B"))

      poset.add_direct_edge("C", "D")
      assert(poset.edge?("C", "D"))
      refute(poset.edge?("A", "C"))
      refute(poset.edge?("A", "D"))

      poset.add_direct_edge("E", "C")
      assert(poset.edge?("E", "C"))
      assert(poset.edge?("E", "D"))

      poset.add_direct_edge("B", "F")
      assert(poset.direct_edge?("B", "F"))
      assert(poset.edge?("B", "F"))
      assert(poset.edge?("A", "F"))

      poset.add_direct_edge("D", "F")
      assert(poset.edge?("A", "F"))
      assert(poset.edge?("B", "F"))
      assert(poset.edge?("C", "F"))
      assert(poset.edge?("D", "F"))
      assert(poset.edge?("E", "F"))

      poset.add_direct_edge("A", "C")
      assert(poset.edge?("A", "F"))
      assert(poset.edge?("B", "F"))
      assert(poset.edge?("C", "F"))
      assert(poset.edge?("D", "F"))
      assert(poset.edge?("E", "F"))
    end

    def test_update_transitive_edges
      poset = Poset[String].new

      poset.add_direct_edge("A", "B")
      poset.add_direct_edge("B", "C")
      poset.add_direct_edge("D", "E")
      poset.add_direct_edge("C", "D")

      assert(poset.edge?("A", "B"))
      assert(poset.edge?("A", "C"))
      assert(poset.edge?("A", "D"))
      assert(poset.edge?("A", "E"))
    end

    def test_get_element
      poset = Poset[String].new

      poset.add_direct_edge("A", "B")
      poset.add_direct_edge("C", "D")
      poset.add_direct_edge("E", "C")
      poset.add_direct_edge("B", "F")
      poset.add_direct_edge("D", "F")
      poset.add_direct_edge("A", "C")

      a = poset["A"]
      assert_equal(["B", "C"], a.parents.sort)
      assert_equal(["B", "C", "D", "F"], a.ancestors.sort)
      assert_empty(a.children)
      assert_empty(a.descendants)

      b = poset["B"]
      assert_equal(["F"], b.parents)
      assert_equal(["F"], b.ancestors)
      assert_equal(["A"], b.children)
      assert_equal(["A"], b.descendants)

      c = poset["C"]
      assert_equal(["D"], c.parents)
      assert_equal(["D", "F"], c.ancestors.sort)
      assert_equal(["A", "E"], c.children.sort)
      assert_equal(["A", "E"], c.descendants.sort)

      d = poset["D"]
      assert_equal(["F"], d.parents)
      assert_equal(["F"], d.ancestors)
      assert_equal(["C"], d.children)
      assert_equal(["A", "C", "E"], d.descendants.sort)

      e = poset["E"]
      assert_equal(["C"], e.parents)
      assert_equal(["C", "D", "F"], e.ancestors.sort)
      assert_empty(e.children)
      assert_empty(e.descendants)

      f = poset["F"]
      assert_empty(f.parents)
      assert_empty(f.ancestors)
      assert_equal(["B", "D"], f.children.sort)
      assert_equal(["A", "B", "C", "D", "E"], f.descendants.sort)
    end

    def test_elements_comparison
      poset = Poset[String].new

      poset.add_direct_edge("A", "B")
      poset.add_direct_edge("B", "C")
      poset.add_direct_edge("D", "E")

      a = poset["A"]
      b = poset["B"]
      c = poset["C"]
      d = poset["D"]
      e = poset["E"]

      assert_equal(0, a <=> a) # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
      assert_equal(-1, a <=> b)
      assert_equal(1, b <=> a)
      assert_equal(-1, a <=> c)
      assert_equal(1, c <=> a)
      assert_nil(a <=> e)
      assert_nil(e <=> a)
      assert_nil(a <=> d)
      assert_nil(d <=> a)
    end
  end
end
