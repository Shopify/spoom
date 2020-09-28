# typed: true
# frozen_string_literal: true

require 'shellwords'

require_relative '../command_helper'
require_relative "../../sorbet/lsp"

module Spoom
  module Cli
    module Commands
      class LSP < Thor
        include Spoom::Cli::CommandHelper

        default_task :show

        desc "interactive", "interactive LSP mode"
        def show
          in_sorbet_project!
          lsp = lsp_client
          # TODO: run interactive mode
          puts lsp
        end

        desc "list", "list all known symbols"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def list
          run do |client|
            Dir["**/*.rb"].each do |file|
              res = client.document_symbols(file.to_uri)
              next if res.empty?
              puts "Symbols from `#{file}`:"
              print_object(res)
            end
          end
        end

        desc "hover", "request hover informations"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def hover(file, line, col)
          run do |client|
            res = client.hover(file.to_uri, line.to_i, col.to_i)
            say "Hovering `#{file}:#{line}:#{col}`:"
            if res
              print_object(res)
            else
              puts "<no data>"
            end
          end
        end

        desc "defs", "list definitions of a symbol"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def defs(file, line, col)
          run do |client|
            res = client.definitions(file.to_uri, line.to_i, col.to_i)
            puts "Definitions for `#{file}:#{line}:#{col}`:"
            print_list(res)
          end
        end

        desc "find", "find symbols matching a query"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def find(query)
          run do |client|
            res = client.symbols(query).reject { |symbol| symbol.location.uri.start_with?("https") }
            puts "Symbols matching `#{query}`:"
            res.each { |symbol| print_object(symbol) }
          end
        end

        desc "symbols", "list symbols from a file"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def symbols(file)
          run do |client|
            res = client.document_symbols(file.to_uri)
            puts "Symbols from `#{file}`:"
            res.each { |symbol| print_object(symbol) }
          end
        end

        desc "refs", "list references to a symbol"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def refs(file, line, col)
          run do |client|
            res = client.references(file.to_uri, line.to_i, col.to_i)
            puts "References to `#{file}:#{line}:#{col}`:"
            print_list(res)
          end
        end

        desc "sigs", "list signatures for a symbol"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def sigs(file, line, col)
          run do |client|
            res = client.signatures(file.to_uri, line.to_i, col.to_i)
            puts "Signature for `#{file}:#{line}:#{col}`:"
            print_list(res)
          end
        end

        desc "types", "display type of a symbol"
        # TODO: options, filter, limit, kind etc.. filter rbi
        def types(file, line, col)
          run do |client|
            res = client.type_definitions(file.to_uri, line.to_i, col.to_i)
            say "Type for `#{file}:#{line}:#{col}`:"
            print_list(res)
          end
        end

        no_commands do
          def lsp_client
            in_sorbet_project!
            client = Spoom::LSP::Client.new(
              Spoom::Config::SORBET_PATH,
              "--lsp",
              "--enable-all-experimental-lsp-features",
              "--disable-watchman",
            )
            client.open(Spoom::Config::WORKSPACE_PATH)
            client
          end

          def print_list(list)
            printer = Spoom::LSP::SymbolPrinter.new(indent_level: 1, colors: !options["no_color"])
            list.each do |item|
              printer.printt
              printer.print("* ")
              printer.print_object(item)
              printer.printn
            end
          end

          def print_object(object)
            printer = Spoom::LSP::SymbolPrinter.new(indent_level: 2, colors: !options["no_color"])
            printer.print_object(object)
          end

          def run(&block)
            client = lsp_client
            block.call(client)
          rescue Spoom::LSP::Error::Diagnostics => err
            say_error("Sorbet returned typechecking errors for `#{err.uri.from_uri}`")
            err.diagnostics.each do |d|
              say_error("#{d.message} (#{d.code})", "  #{d.range}")
            end
            exit(1)
          rescue Spoom::LSP::Error::BadHeaders => err
            say_error("Sorbet didn't answer correctly (#{err.message})")
            exit(1)
          rescue Spoom::LSP::Error => err
            say_error(err.message)
            exit(1)
          ensure
            begin
              client&.close
            rescue
              # We can't do much if Sorbet refuse to close.
              # We kill the parent process and let the child be killed.
              exit(1)
            end
          end
        end
      end
    end
  end
end
