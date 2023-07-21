# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class Printer < Visitor
      extend T::Sig

      sig { returns(String) }
      attr_reader :out

      sig { void }
      def initialize
        super

        @out = T.let(String.new, String)
        @indent_level = T.let(0, Integer)
      end

      # Printing

      sig { void }
      def indent
        @indent_level += 2
      end

      sig { void }
      def dedent
        @indent_level -= 2
      end

      sig { params(string: T.nilable(String)).void }
      def print(string)
        return unless string

        @out << string
      end

      sig { params(string: T.nilable(String)).void }
      def printn(string = nil)
        print(string) if string
        print("\n")
      end

      sig { params(string: T.nilable(String)).void }
      def printl(string)
        return unless string

        printt
        print(string)
        printn
      end

      sig { params(string: T.nilable(String)).void }
      def printt(string = nil)
        print(" " * @indent_level)
        print(string) if string
      end

      # Visit

      sig { override.params(symbol: Class).void }
      def visit_class(symbol)
        printl("# #{symbol.location}")
        printt("class #{symbol.full_name}")
        superclass = symbol.superclass
        case superclass
        when Ref
          print(" < Ref[#{superclass.full_name}]")
        when Class
          print(" < #{superclass.full_name}")
        end
        printn
        indent
        super
        dedent
        printl("end")
      end

      sig { override.params(symbol: Module).void }
      def visit_module(symbol)
        printl("# #{symbol.location}")
        printl("module #{symbol.full_name}")
        indent
        super
        dedent
        printl("end")
      end

      # Properties

      sig { override.params(symbol: Attr).void }
      def visit_attr(symbol)
        printl("# #{symbol.location}")
        printl("#{symbol.kind} #{symbol.name}")
      end

      sig { override.params(symbol: Method).void }
      def visit_method(symbol)
        printl("# #{symbol.location}")
        printl("def #{symbol.name}; end")
      end

      sig { override.params(symbol: Prop).void }
      def visit_prop(symbol)
        printl("# #{symbol.location}")
        printt
        if symbol.read_only
          print("const")
        else
          print("prop")
        end
        printn(" #{symbol.name}, type: #{symbol.type}")
      end
    end
  end
end
