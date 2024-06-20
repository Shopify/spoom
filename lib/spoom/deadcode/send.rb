# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    # An abstraction to simplify handling of Prism::CallNode nodes.
    class Send < T::Struct
      extend T::Sig

      const :node, Prism::CallNode
      const :name, String
      const :recv, T.nilable(Prism::Node), default: nil
      const :args, T::Array[Prism::Node], default: []
      const :block, T.nilable(Prism::Node), default: nil
      const :location, Location

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

      sig { params(block: T.proc.params(key: Prism::Node, value: T.nilable(Prism::Node)).void).void }
      def each_arg_assoc(&block)
        args.each do |arg|
          next unless arg.is_a?(Prism::KeywordHashNode) || arg.is_a?(Prism::HashNode)

          arg.elements.each do |assoc|
            yield(assoc.key, assoc.value) if assoc.is_a?(Prism::AssocNode)
          end
        end
      end
    end
  end
end
