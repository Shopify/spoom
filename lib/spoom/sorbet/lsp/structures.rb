# typed: true
# frozen_string_literal: true

require_relative "../../printer"

module Spoom
  module LSP
    module PrintableSymbol
      extend T::Sig
      extend T::Helpers

      interface!

      sig { abstract.params(printer: SymbolPrinter).void }
      def accept_printer(printer); end
    end

    class Hover < T::Struct
      extend T::Sig
      include PrintableSymbol

      const :contents, String
      const :range, T.nilable(Range)

      def self.from_json(json)
        Hover.new(
          contents: json['contents']['value'],
          range: json['range'] ? Range.from_json(json['range']) : nil
        )
      end

      sig { override.params(printer: SymbolPrinter).void }
      def accept_printer(printer)
        printer.print("#{contents}\n")
        printer.print_object(range) if range
      end

      def to_s
        "#{contents} (#{range})."
      end
    end

    class Position < T::Struct
      extend T::Sig
      include PrintableSymbol

      const :line, Integer
      const :char, Integer

      def self.from_json(json)
        Position.new(
          line: json['line'].to_i,
          char: json['character'].to_i
        )
      end

      sig { override.params(printer: SymbolPrinter).void }
      def accept_printer(printer)
        printer.print_colored("#{line}:#{char}", :light_black)
      end

      def to_s
        "#{line}:#{char}"
      end
    end

    class Range < T::Struct
      extend T::Sig
      include PrintableSymbol

      const :start, Position
      const :end, Position

      def self.from_json(json)
        Range.new(
          start: Position.from_json(json['start']),
          end: Position.from_json(json['end'])
        )
      end

      sig { override.params(printer: SymbolPrinter).void }
      def accept_printer(printer)
        printer.print_object(start)
        printer.print_colored("-", :light_black)
        printer.print_object(self.end)
      end

      def to_s
        "#{start}-#{self.end}"
      end
    end

    class Location < T::Struct
      extend T::Sig
      include PrintableSymbol

      const :uri, String
      const :range, LSP::Range

      def self.from_json(json)
        Location.new(
          uri: json['uri'],
          range: Range.from_json(json['range'])
        )
      end

      sig { override.params(printer: SymbolPrinter).void }
      def accept_printer(printer)
        printer.print_colored("#{printer.clean_uri(uri)}:", :light_black)
        printer.print_object(range)
      end

      def to_s
        "#{uri}:#{range}"
      end
    end

    class SignatureHelp < T::Struct
      extend T::Sig
      include PrintableSymbol

      const :label, T.nilable(String)
      const :doc, Object # TODO
      const :params, T::Array[T.untyped] # TODO

      def self.from_json(json)
        SignatureHelp.new(
          label: json['label'],
          doc: json['documentation'],
          params: json['parameters'],
        )
      end

      sig { override.params(printer: SymbolPrinter).void }
      def accept_printer(printer)
        printer.print(label)
        printer.print("(")
        printer.print(params.map { |l| "#{l['label']}: #{l['documentation']}" }.join(", "))
        printer.print(")")
      end

      def to_s
        "#{label}(#{params})."
      end
    end

    class Diagnostic < T::Struct
      extend T::Sig
      include PrintableSymbol

      const :range, LSP::Range
      const :code, Integer
      const :message, String
      const :informations, Object

      def self.from_json(json)
        Diagnostic.new(
          range: Range.from_json(json['range']),
          code: json['code'].to_i,
          message: json['message'],
          informations: json['relatedInformation']
        )
      end

      sig { override.params(printer: SymbolPrinter).void }
      def accept_printer(printer)
        printer.print(to_s)
      end

      def to_s
        "Error: #{message} (#{code})."
      end
    end

    class DocumentSymbol < T::Struct
      extend T::Sig
      include PrintableSymbol

      const :name, String
      const :detail, T.nilable(String)
      const :kind, Integer
      const :location, T.nilable(Location)
      const :range, T.nilable(Range)
      const :children, T::Array[DocumentSymbol]

      def self.from_json(json)
        DocumentSymbol.new(
          name: json['name'],
          detail: json['detail'],
          kind: json['kind'],
          location: json['location'] ? Location.from_json(json['location']) : nil,
          range: json['range'] ? Range.from_json(json['range']) : nil,
          children: json['children'] ? json['children'].map { |symbol| DocumentSymbol.from_json(symbol) } : [],
        )
      end

      sig { override.params(printer: SymbolPrinter).void }
      def accept_printer(printer)
        h = serialize.hash
        return if printer.seen.include?(h)
        printer.seen.add(h)

        printer.printt
        printer.print(kind_string)
        printer.print(' ')
        printer.print_colored(name, :blue, :bold)
        printer.print_colored(' (', :light_black)
        if range
          printer.print_object(range)
        elsif location
          printer.print_object(location)
        end
        printer.print_colored(')', :light_black)
        printer.printn
        unless children.empty?
          printer.indent
          printer.print_objects(children)
          printer.dedent
        end
        # TODO: also display details?
      end

      def to_s
        "#{name} (#{range})"
      end

      def kind_string
        return "<unknown:#{kind}>" unless SYMBOL_KINDS.key?(kind)
        SYMBOL_KINDS[kind]
      end

      SYMBOL_KINDS = {
        1 => "file",
        2 => "module",
        3 => "namespace",
        4 => "package",
        5 => "class",
        6 => "def",
        7 => "property",
        8 => "field",
        9 => "constructor",
        10 => "enum",
        11 => "interface",
        12 => "function",
        13 => "variable",
        14 => "const",
        15 => "string",
        16 => "number",
        17 => "boolean",
        18 => "array",
        19 => "object",
        20 => "key",
        21 => "null",
        22 => "enum_member",
        23 => "struct",
        24 => "event",
        25 => "operator",
        26 => "type_parameter",
      }
    end

    class SymbolPrinter < Printer
      extend T::Sig

      attr_accessor :seen, :prefix

      sig do
        params(
          out: T.any(IO, StringIO),
          colors: T::Boolean,
          indent_level: Integer,
          prefix: T.nilable(String)
        ).void
      end
      def initialize(out: $stdout, colors: true, indent_level: 0, prefix: nil)
        super(out: out, colors: colors, indent_level: indent_level)
        @seen = Set.new
        @out = out
        @colors = colors
        @indent_level = indent_level
        @prefix = prefix
      end

      sig { params(object: T.nilable(PrintableSymbol)).void }
      def print_object(object)
        return unless object
        object.accept_printer(self)
      end

      sig { params(objects: T::Array[PrintableSymbol]).void }
      def print_objects(objects)
        objects.each { |object| print_object(object) }
      end

      sig { params(uri: String).returns(String) }
      def clean_uri(uri)
        return uri unless prefix
        uri.delete_prefix(prefix)
      end

      sig { params(objects: T::Array[PrintableSymbol]).void }
      def print_list(objects)
        objects.each do |object|
          printt
          print "* "
          print_object(object)
          printn
        end
      end
    end
  end
end
