# typed: strict
# frozen_string_literal: true

require "cgi"

module Spoom
  class Typecheck < Visitor
    extend T::Sig

    sig { params(node: Prism::Node, file: String).void }
    def initialize(node, file)
      @node = node
      @file = file
    end

    sig { override.params(node: Prism::CallNode).void }
    def visit_call_node(node)
      send = node.send
      raise unless send

      return if send.is_a?(UnresolvedSend)

      method = send.method
        unless method
          puts "Error: unknown method `#{method}` in type `#{recv_type}`"
          return
        end

        unless @node.arguments.arguments.size == method.arity
          puts "Error: wrong number of arguments for method `#{method}`: expected #{method.arity}, got #{@node.arguments.arguments.size}"
          return
        end

        node.arguments.arguments.each_with_index do |arg, index|
          arg_type = type_for(arg)
          expected_type = method.arg_types[index]
          unless arg_type <= expected_type
            puts "Error: invalid arguments for method `#{method}`: expected #{expected_type}, got #{arg_type}"
            nil
          end
        end

        super
      end

      private

      sig { params(node: Prism::Node).returns(Type) }
      def type_for(node)
        raw = case node
        when Prism::IntegerNode
          "Integer"
        when Prism::StringNode
          "String"
        when Prism::SymbolNode
          "Symbol"
        else
          "untyped"
        end
        Type.new(raw)
      end
    end
  end

  # class Error
  #   extend T::Sig

  #   sig { returns(String) }
  #   attr_reader :message

  #   sig { params(message: String).void }
  #   def initialize(message)
  #     @message = message
  #   end
  # end

  class Send
    extend T::Sig

    # sig { returns(Prism::Node) }
    # attr_reader :node

    sig { params(node: Prism::CallNode).void }
    def initialize(node)
      @node = node
    end

    sig { returns(T::Array[Error]) }
    def validate
      errors = T.let([], T::Array[Error])
    end
  end

  class Type
    extend T::Sig

    sig { returns(String) }
    attr_reader :raw

    sig { params(raw: String).void }
    def initialize(raw)
      @raw = raw
    end

    sig { params(other: Type).returns(T::Boolean) }
    def <=(other)
      false
    end
  end
end
