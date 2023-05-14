# typed: strict
# frozen_string_literal: true

require "syntax_tree"

module Spoom
  module Model
    class Parser
      class << self
        extend T::Sig

        sig { params(path: String).returns(SyntaxTree::Node) }
        def parse_file(path)
          SyntaxTree.parse_file(path)
        end

        sig { params(ruby: String).returns(SyntaxTree::Node) }
        def parse_string(ruby)
          SyntaxTree.parse(ruby)
        end
      end
    end
  end
end
