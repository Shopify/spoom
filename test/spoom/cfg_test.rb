# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class CFGTest < Minitest::Test
    extend T::Sig

    def test_empty
    end

    private

    sig { params(code: String, compact: T::Boolean).returns(CFG::Cluster) }
    def parse(code, compact: true)
      node = Spoom.parse_ruby(code, file: "-")
      cfg = CFG.from_node(node)
      cfg.compact! if compact
      cfg
    end
  end
end
