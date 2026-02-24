# typed: strict
# frozen_string_literal: true

require_relative "../../printer"
require "set"

module Spoom
  module LSP
    # @interface
    module PrintableSymbol
      # @abstract
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer) = raise NotImplementedError, "Abstract method called"
    end

    class Hover
      include PrintableSymbol

      #: String
      attr_reader :contents

      #: Range?
      attr_reader :range

      #: (contents: String, ?range: Range?) -> void
      def initialize(contents:, range: nil)
        @contents = contents
        @range = range
      end

      class << self
        #: (Hash[untyped, untyped] json) -> Hover
        def from_json(json)
          Hover.new(
            contents: json["contents"]["value"],
            range: json["range"] ? Range.from_json(json["range"]) : nil,
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print("#{contents}\n")
        printer.print_object(range) if range
      end

      #: -> String
      def to_s
        "#{contents} (#{range})."
      end
    end

    class Position
      include PrintableSymbol

      #: Integer
      attr_reader :line

      #: Integer
      attr_reader :char

      #: (line: Integer, char: Integer) -> void
      def initialize(line:, char:)
        @line = line
        @char = char
      end

      class << self
        #: (Hash[untyped, untyped] json) -> Position
        def from_json(json)
          Position.new(
            line: json["line"].to_i,
            char: json["character"].to_i,
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print_colored("#{line}:#{char}", Color::LIGHT_BLACK)
      end

      #: -> String
      def to_s
        "#{line}:#{char}"
      end
    end

    class Range
      include PrintableSymbol

      #: Position
      attr_reader :start_pos

      #: Position
      attr_reader :end_pos

      #: (start_pos: Position, end_pos: Position) -> void
      def initialize(start_pos:, end_pos:)
        @start_pos = start_pos
        @end_pos = end_pos
      end

      class << self
        #: (Hash[untyped, untyped] json) -> Range
        def from_json(json)
          Range.new(
            start_pos: Position.from_json(json["start"]),
            end_pos: Position.from_json(json["end"]),
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print_object(start_pos)
        printer.print_colored("-", Color::LIGHT_BLACK)
        printer.print_object(end_pos)
      end

      #: -> String
      def to_s
        "#{start_pos}-#{end_pos}"
      end
    end

    class Location
      include PrintableSymbol

      #: String
      attr_reader :uri

      #: Range
      attr_reader :range

      #: (uri: String, range: Range) -> void
      def initialize(uri:, range:)
        @uri = uri
        @range = range
      end

      class << self
        #: (Hash[untyped, untyped] json) -> Location
        def from_json(json)
          Location.new(
            uri: json["uri"],
            range: Range.from_json(json["range"]),
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print_colored("#{printer.clean_uri(uri)}:", Color::LIGHT_BLACK)
        printer.print_object(range)
      end

      #: -> String
      def to_s
        "#{uri}:#{range}"
      end
    end

    class SignatureHelp
      include PrintableSymbol

      #: String?
      attr_reader :label

      # TODO
      #: Object
      attr_reader :doc

      # TODO
      #: Array[untyped]
      attr_reader :params

      #: (doc: Object, params: Array[untyped], ?label: String?) -> void
      def initialize(doc:, params:, label: nil)
        @label = label
        @doc = doc
        @params = params
      end

      class << self
        #: (Hash[untyped, untyped] json) -> SignatureHelp
        def from_json(json)
          SignatureHelp.new(
            label: json["label"],
            doc: json["documentation"],
            params: json["parameters"],
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print(label)
        printer.print("(")
        printer.print(params.map { |l| "#{l["label"]}: #{l["documentation"]}" }.join(", "))
        printer.print(")")
      end

      #: -> String
      def to_s
        "#{label}(#{params})."
      end
    end

    class Diagnostic
      include PrintableSymbol

      #: Range
      attr_reader :range

      #: Integer
      attr_reader :code

      #: String
      attr_reader :message

      #: Object
      attr_reader :information

      #: (range: Range, code: Integer, message: String, information: Object) -> void
      def initialize(range:, code:, message:, information:)
        @range = range
        @code = code
        @message = message
        @information = information
      end

      class << self
        #: (Hash[untyped, untyped] json) -> Diagnostic
        def from_json(json)
          Diagnostic.new(
            range: Range.from_json(json["range"]),
            code: json["code"].to_i,
            message: json["message"],
            information: json["relatedInformation"],
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        printer.print(to_s)
      end

      #: -> String
      def to_s
        "Error: #{message} (#{code})."
      end
    end

    class DocumentSymbol
      include PrintableSymbol

      #: String
      attr_reader :name

      #: String?
      attr_reader :detail

      #: Integer
      attr_reader :kind

      #: Location?
      attr_reader :location

      #: Range?
      attr_reader :range

      #: Array[DocumentSymbol]
      attr_reader :children

      #: (
      #|   name: String,
      #|   kind: Integer,
      #|   children: Array[DocumentSymbol],
      #|   ?detail: String?,
      #|   ?location: Location?,
      #|   ?range: Range?
      #| ) -> void
      def initialize(name:, kind:, children:, detail: nil, location: nil, range: nil)
        @name = name
        @detail = detail
        @kind = kind
        @location = location
        @range = range
        @children = children
      end

      class << self
        #: (Hash[untyped, untyped] json) -> DocumentSymbol
        def from_json(json)
          DocumentSymbol.new(
            name: json["name"],
            detail: json["detail"],
            kind: json["kind"],
            location: json["location"] ? Location.from_json(json["location"]) : nil,
            range: json["range"] ? Range.from_json(json["range"]) : nil,
            children: json["children"] ? json["children"].map { |symbol| DocumentSymbol.from_json(symbol) } : [],
          )
        end
      end

      # @override
      #: (SymbolPrinter printer) -> void
      def accept_printer(printer)
        h = hash
        return if printer.seen.include?(h)

        printer.seen.add(h)

        printer.printt
        printer.print(kind_string)
        printer.print(" ")
        printer.print_colored(name, Color::BLUE, Color::BOLD)
        printer.print_colored(" (", Color::LIGHT_BLACK)
        if range
          printer.print_object(range)
        elsif location
          printer.print_object(location)
        end
        printer.print_colored(")", Color::LIGHT_BLACK)
        printer.printn
        unless children.empty?
          printer.indent
          printer.print_objects(children)
          printer.dedent
        end
        # TODO: also display details?
      end

      #: -> String
      def to_s
        "#{name} (#{range})"
      end

      #: -> String
      def kind_string
        SYMBOL_KINDS[kind] || "<unknown:#{kind}>"
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
      } #: Hash[Integer, String]
    end

    class SymbolPrinter < Printer
      #: Set[Integer]
      attr_reader :seen

      #: String?
      attr_accessor :prefix

      #: (?out: (IO | StringIO), ?colors: bool, ?indent_level: Integer, ?prefix: String?) -> void
      def initialize(out: $stdout, colors: true, indent_level: 0, prefix: nil)
        super(out: out, colors: colors, indent_level: indent_level)
        @seen = Set.new #: Set[Integer]
        @out = out
        @colors = colors
        @indent_level = indent_level
        @prefix = prefix
      end

      #: (PrintableSymbol? object) -> void
      def print_object(object)
        return unless object

        object.accept_printer(self)
      end

      #: (Array[PrintableSymbol] objects) -> void
      def print_objects(objects)
        objects.each { |object| print_object(object) }
      end

      #: (String uri) -> String
      def clean_uri(uri)
        prefix = self.prefix
        return uri unless prefix

        uri.delete_prefix(prefix)
      end

      #: (Array[PrintableSymbol] objects) -> void
      def print_list(objects)
        objects.each do |object|
          printt
          print("* ")
          print_object(object)
          printn
        end
      end
    end
  end
end
