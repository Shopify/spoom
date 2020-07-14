# typed: true
# frozen_string_literal: true

require "colorize"

module Spoom
  module Cli
    class SymbolPrinter
      attr_accessor :seen, :no_color

      def self.print_list(list, no_color)
        printer = SymbolPrinter.new(2, no_color)
        list.each do |item|
          printer.print(" * ")
          printer.visit(item)
          printer.printn
        end
      end

      def self.print_object(object, no_color)
        printer = SymbolPrinter.new(2, no_color)
        printer.visit(object)
      end

      def initialize(default_indent, no_color = false)
        @seen = Set.new
        @current_indent = default_indent
        @no_color = no_color
        String.disable_colorization = no_color
      end

      def indent
        @current_indent += 2
      end

      def dedent
        @current_indent -= 2
      end

      def print(string)
        Kernel.print(string)
      end

      def printn
        print("\n")
      end

      def printt
        print(" " * @current_indent)
      end

      def visit(object)
        if object.is_a?(Array)
          object.each { |e| visit(e) }
        else
          object.accept_printer(self)
        end
      end
    end
  end
end

class String
  def to_uri
    "file://" + File.join(Spoom::Config::WORKSPACE_PATH, self)
  end

  def from_uri
    sub("file://#{Spoom::Config::WORKSPACE_PATH}", "")
  end
end
