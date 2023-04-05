# typed: strict
# frozen_string_literal: true

require "stringio"

module Spoom
  class Printer
    extend T::Sig
    extend T::Helpers

    include Colorize

    sig { returns(T.any(IO, StringIO)) }
    attr_accessor :out

    sig { params(out: T.any(IO, StringIO), colors: T::Boolean, indent_level: Integer).void }
    def initialize(out: $stdout, colors: true, indent_level: 0)
      @out = out
      @colors = colors
      @indent_level = indent_level
    end

    # Increase indent level
    sig { void }
    def indent
      @indent_level += 2
    end

    # Decrease indent level
    sig { void }
    def dedent
      @indent_level -= 2
    end

    # Print `string` into `out`
    sig { params(string: T.nilable(String)).void }
    def print(string)
      return unless string

      @out.print(string)
    end

    # Print `string` colored with `color` into `out`
    #
    # Does not use colors unless `@colors`.
    sig { params(string: T.nilable(String), color: Color).void }
    def print_colored(string, *color)
      return unless string

      string = T.unsafe(self).colorize(string, *color)
      @out.print(string)
    end

    # Print a new line into `out`
    sig { void }
    def printn
      print("\n")
    end

    # Print `string` with indent and newline
    sig { params(string: T.nilable(String)).void }
    def printl(string)
      return unless string

      printt
      print(string)
      printn
    end

    # Print an indent space into `out`
    sig { void }
    def printt
      print(" " * @indent_level)
    end

    # Colorize `string` with color if `@colors`
    sig { params(string: String, color: Spoom::Color).returns(String) }
    def colorize(string, *color)
      return string unless @colors

      T.unsafe(self).set_color(string, *color)
    end
  end
end
