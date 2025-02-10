# typed: true
# frozen_string_literal: true

require "shellwords"

module Spoom
  module Cli
    module Srb
      class LSP < Thor
        include Helper

        class SymbolPrinter < Printer
          extend T::Sig

          sig { returns(T::Set[Integer]) }
          attr_reader :seen

          sig { returns(T.nilable(String)) }
          attr_accessor :prefix

          sig do
            params(
              out: T.any(IO, StringIO),
              colors: T::Boolean,
              indent_level: Integer,
              prefix: T.nilable(String),
            ).void
          end
          def initialize(out: $stdout, colors: true, indent_level: 0, prefix: nil)
            super(out: out, colors: colors, indent_level: indent_level)
            @seen = T.let(Set.new, T::Set[Integer])
            @out = out
            @colors = colors
            @indent_level = indent_level
            @prefix = prefix
          end

          sig { params(objects: T::Array[T::Hash[String, T.untyped]]).void }
          def print_locations(objects)
            objects.each do |object|
              printt
              print("* ")
              print_location(object)
              printn
            end
          end

          sig { params(object: T.nilable(T::Hash[String, T.untyped])).void }
          def print_object(object)
            return unless object
            return if seen.include?(object.object_id)

            seen.add(object.object_id)

            printt
            print(symbol_kind(object["kind"]))
            print(" ")
            print_colored(object["name"], Color::BLUE, Color::BOLD)
            print_colored(" (", Color::LIGHT_BLACK)

            range = object["range"]
            location = object["location"]
            if range
              print_range(range)
            elsif location
              print_location(location)
            end

            print_colored(")", Color::LIGHT_BLACK)
            printn

            children = object.fetch("children", [])
            unless children.empty?
              indent
              print_objects(children)
              dedent
            end

            # TODO: also display details?
          end

          sig { params(objects: T::Array[T::Hash[String, T.untyped]]).void }
          def print_objects(objects)
            objects.each { |object| print_object(object) }
          end

          sig { params(position: T::Hash[String, T.untyped]).void }
          def print_position(position)
            print_colored(position["line"].to_s, Color::LIGHT_BLACK)
            print_colored(":", Color::LIGHT_BLACK)
            print_colored(position["character"].to_s, Color::LIGHT_BLACK)
          end

          sig { params(range: T::Hash[String, T.untyped]).void }
          def print_range(range)
            print_position(range["start"])
            print_colored("-", Color::LIGHT_BLACK)
            print_position(range["end"])
          end

          sig { params(location: T::Hash[String, T.untyped]).void }
          def print_location(location)
            print_colored(clean_uri(location["uri"]), Color::LIGHT_BLACK)
            print_colored(":", Color::LIGHT_BLACK)
            print_range(location["range"])
          end

          sig { params(uri: String).returns(String) }
          def clean_uri(uri)
            prefix = self.prefix
            return uri unless prefix

            uri.delete_prefix(prefix)
          end

          sig { params(objects: T::Array[T::Hash[String, T.untyped]]).void }
          def print_list(objects)
            puts objects.inspect
            objects.each do |object|
              printt
              print("* ")
              print_object(object)
              printn
            end
          end

          private

          sig { params(kind: T.nilable(Integer)).returns(String) }
          def symbol_kind(kind)
            return "<unknown:#{kind}>" unless kind

            SYMBOL_KINDS[kind] || "<unknown:#{kind}>"
          end

          SYMBOL_KINDS = T.let(
            {
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
            },
            T::Hash[Integer, String],
          )
        end

        module LSPHelper
          extend T::Sig
          extend T::Helpers

          requires_ancestor { Helper }

          sig { returns(Spoom::LSP::Client) }
          def lsp_client
            context_requiring_sorbet!

            path = exec_path

            client = Spoom::LSP::Client.new(
              Spoom::Sorbet::BIN_PATH,
              "--lsp",
              "--enable-all-experimental-lsp-features",
              "--disable-watchman",
              # "-v",
              chdir: path,
            )

            client.on_diagnostics do |diagnostics|
              printer = symbol_printer(out: $stderr)

              file = printer.clean_uri(diagnostics["uri"])
              printer.print_colored("Error: Sorbet returned typechecking errors for `#{file}`", Color::RED)
              printer.printn
              diagnostics["diagnostics"].each do |diagnostic|
                printer.print("  ")
                printer.print_range(diagnostic["range"])
                printer.print(": ")
                printer.print(diagnostic["message"])
                printer.print(" (")
                printer.print(diagnostic["code"].to_s)
                printer.print(")")
                printer.printn
              end
            end

            client.request("initialize", {
              rootPath: File.expand_path(path),
              rootUri: to_uri(path),
              capabilities: {},
            })

            client.notify("initialized", {})

            client
          end

          sig { params(block: T.proc.params(client: Spoom::LSP::Client).returns(T.untyped)).void }
          def run(&block)
            client = T.let(lsp_client, Spoom::LSP::Client)
            block.call(client)
          rescue Spoom::LSP::Client::Error => err
            say_error(err.message)
            exit(1)
          rescue => err
            say_error(err.message)
            # exit(1)
          ensure
            begin
              client&.shutdown
            rescue
              # We can't do much if Sorbet refuse to shutdown.
              # We kill the parent process and let the child be killed.
              exit(1)
            end
          end

          def to_uri(path)
            "file://" + File.expand_path(File.join(exec_path), path)
          end

          sig { params(out: IO).returns(SymbolPrinter) }
          def symbol_printer(out: $stdout)
            SymbolPrinter.new(
              out: out,
              indent_level: 2,
              colors: options[:color],
              prefix: "file://#{File.expand_path(exec_path)}",
            )
          end
        end

        include LSPHelper

        desc "list", "List all known symbols"
        def list
          run do |client|
            printer = symbol_printer
            Dir["**/*.rb"].each do |file|
              res = client.request(
                "textDocument/documentSymbol",
                {
                  textDocument: { uri: to_uri(file) },
                },
              )
              next unless res

              say("Symbols from `#{file}`:")
              printer.print_objects(res)
            end
          end
        end

        desc "hover", "Request hover information"
        def hover(file, line, col)
          run do |client|
            say("Hovering `#{file}:#{line}:#{col}`:")
            res = client.request(
              "textDocument/hover",
              {
                textDocument: { uri: to_uri(file) },
                position: { line: line.to_i, character: col.to_i },
              },
            )
            puts res.dig("contents", "value")
          end
        end

        desc "defs", "List definitions of a symbol"
        def defs(file, line, col)
          run do |client|
            res = client.request(
              "textDocument/definition",
              {
                textDocument: { uri: to_uri(file) },
                position: { line: line.to_i, character: col.to_i },
              },
            )
            say("Definitions for `#{file}:#{line}:#{col}`:")
            symbol_printer.print_locations(res)
          end
        end

        desc "find", "Find symbols matching a query"
        def find(query)
          run do |client|
            res = client.request(
              "workspace/symbol",
              query: query,
            )
            say("Symbols matching `#{query}`:")
            res.reject! { |object| object.dig("location", "uri").start_with?("https://") }
            symbol_printer.print_objects(res)
          end
        end

        desc "symbols", "List symbols from a file"
        def symbols(file)
          run do |client|
            res = client.request(
              "textDocument/documentSymbol",
              {
                textDocument: { uri: to_uri(file) },
              },
            )
            say("Symbols from `#{file}`:")
            symbol_printer.print_objects(res)
          end
        end

        desc "refs", "List references to a symbol"
        def refs(file, line, col)
          run do |client|
            res = client.request(
              "textDocument/references",
              {
                textDocument: { uri: to_uri(file) },
                position: { line: line.to_i, character: col.to_i },
                context: { includeDeclaration: true },
              },
            )
            say("References to `#{file}:#{line}:#{col}`:")
            symbol_printer.print_locations(res)
          end
        end

        desc "sigs", "List signatures for a symbol"
        def sigs(file, line, col)
          run do |client|
            res = client.request(
              "textDocument/signatureHelp",
              {
                textDocument: { uri: to_uri(file) },
                position: { line: line.to_i, character: col.to_i },
              },
            )
            say("Signature for `#{file}:#{line}:#{col}`:")
            printer = symbol_printer
            res.dig("signatures").each do |signature|
              printer.printt
              printer.print("* ")
              printer.print(signature.dig("label"))
              printer.print("(")
              printer.print(signature.dig("parameters").map { |l| "#{l["label"]}: #{l["documentation"]}" }.join(", "))
              printer.print(")")
              printer.printn
            end
          end
        end

        desc "types", "Display type of a symbol"
        def types(file, line, col)
          run do |client|
            res = client.request(
              "textDocument/typeDefinition",
              {
                textDocument: { uri: to_uri(file) },
                position: { line: line.to_i, character: col.to_i },
              },
            )
            say("Type for `#{file}:#{line}:#{col}`:")
            symbol_printer.print_locations(res)
          end
        end
      end
    end
  end
end
