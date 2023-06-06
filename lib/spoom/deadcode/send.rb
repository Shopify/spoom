# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    # An abstraction to simplify handling of SyntaxTree::CallNode, SyntaxTree::Command, SyntaxTree::CommandCall and
    # SyntaxTree::VCall nodes.
    class Send < T::Struct
      extend T::Sig

      const :node, SyntaxTree::Node
      const :name, String
      const :recv, T.nilable(SyntaxTree::Node), default: nil
      const :args, T::Array[SyntaxTree::Node], default: []
      const :block, T.nilable(SyntaxTree::Node), default: nil
    end
  end
end
