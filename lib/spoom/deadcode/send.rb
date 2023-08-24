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

      sig do
        type_parameters(:T)
          .params(arg_type: T::Class[T.type_parameter(:T)], block: T.proc.params(arg: T.type_parameter(:T)).void)
          .void
      end
      def each_arg(arg_type, &block)
        args.each do |arg|
          yield(T.unsafe(arg)) if arg.is_a?(arg_type)
        end
      end

      sig { params(block: T.proc.params(key: SyntaxTree::Node, value: T.nilable(SyntaxTree::Node)).void).void }
      def each_arg_assoc(&block)
        args.each do |arg|
          next unless arg.is_a?(SyntaxTree::BareAssocHash) || arg.is_a?(SyntaxTree::HashLiteral)

          arg.assocs.each do |assoc|
            yield(assoc.key, assoc.value) if assoc.is_a?(SyntaxTree::Assoc)
          end
        end
      end
    end
  end
end
