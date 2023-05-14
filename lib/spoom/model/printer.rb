# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class Printer < Visitor
      extend T::Sig

      sig { returns(T.any(IO, StringIO)) }
      attr_reader :out

      sig { params(out: T.any(IO, StringIO)).void }
      def initialize(out)
        super()

        @out = out
        @current_indent = T.let(0, Integer)
      end

      sig { params(klass: Class).void }
      def visit_class(klass)
        printt("class #{klass.name}")
        if klass.nodes.empty?
          printn("; end")
        else
          printn
          indent
          super
          dedent
          printl("end")
        end
      end

      private

      sig { params(string: String).void }
      def print(string)
        @out.print(string)
      end

      sig { params(string: T.nilable(String)).void }
      def printt(string = nil)
        print(" " * @current_indent)
        print(string) if string
      end

      sig { params(string: T.nilable(String)).void }
      def printn(string = nil)
        print(string) if string
        print("\n")
      end

      sig { params(string: String).void }
      def printl(string)
        printt
        print(string)
        printn
      end

      sig { void }
      def indent
        @current_indent += 2
      end

      sig { void }
      def dedent
        @current_indent -= 2
      end
    end

    class Node
      extend T::Sig

      sig { returns(String) }
      def string
        out = StringIO.new
        printer = Printer.new(out)
        printer.visit(self)
        out.string
      end
    end
  end
end
