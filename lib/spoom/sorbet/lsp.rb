# typed: true
# frozen_string_literal: true

require 'open3'
require 'json'

require_relative 'lsp/base'
require_relative 'lsp/structures'
require_relative 'lsp/errors'

module Spoom
  module LSP
    class Client
      def initialize(sorbet_cmd, *sorbet_args)
        @id = 0
        Bundler.with_clean_env do
          @in, @out, @err, @status = Open3.popen3([sorbet_cmd, *sorbet_args].join(" "))
        end
      end

      def next_id
        @id += 1
      end

      def send_raw(json_string)
        @in.puts("Content-Length:#{json_string.length}\r\n\r\n#{json_string}")
      end

      def send(message)
        send_raw(message.to_json)
        read if message.is_a?(Request)
      end

      def read_raw
        header = @out.gets

        # Sorbet returned an error and forgot to answer
        raise Error::BadHeaders, "bad response headers" unless header&.match?(/Content-Length: /)

        len = header.slice(::Range.new(16, nil)).to_i
        @out.read(len + 2) # +2 'cause of the final \r\n
      end

      def read
        json = JSON.parse(read_raw)

        # Handle error in the LSP protocol
        raise ResponseError.from_json(json['error']) if json['error']

        # Handle typechecking errors
        raise Error::Diagnostics.from_json(json['params']) if json['method'] == "textDocument/publishDiagnostics"

        json
      end

      # LSP requests

      def open(workspace_path)
        raise Error::AlreadyOpen, "Error: CLI already opened" if @open
        send(Request.new(
          next_id,
          'initialize',
          {
            'rootPath' => workspace_path,
            'rootUri' => "file://#{workspace_path}",
            'capabilities' => {},
          },
        ))
        send(Notification.new('initialized', {}))
        @open = true
      end

      def hover(uri, line, column)
        json = send(Request.new(
          next_id,
          'textDocument/hover',
          {
            'textDocument' => {
              'uri' => uri,
            },
            'position' => {
              'line' => line,
              'character' => column,
            },
          }
        ))
        return nil unless json['result']
        Hover.from_json(json['result'])
      end

      def signatures(uri, line, column)
        json = send(Request.new(
          next_id,
          'textDocument/signatureHelp',
          {
            'textDocument' => {
              'uri' => uri,
            },
            'position' => {
              'line' => line,
              'character' => column,
            },
          }
        ))
        json['result']['signatures'].map { |loc| SignatureHelp.from_json(loc) }
      end

      def definitions(uri, line, column)
        json = send(Request.new(
          next_id,
          'textDocument/definition',
          {
            'textDocument' => {
              'uri' => uri,
            },
            'position' => {
              'line' => line,
              'character' => column,
            },
          }
        ))
        json['result'].map { |loc| Location.from_json(loc) }
      end

      def type_definitions(uri, line, column)
        json = send(Request.new(
          next_id,
          'textDocument/typeDefinition',
          {
            'textDocument' => {
              'uri' => uri,
            },
            'position' => {
              'line' => line,
              'character' => column,
            },
          }
        ))
        json['result'].map { |loc| Location.from_json(loc) }
      end

      def references(uri, line, column, include_decl = true)
        json = send(Request.new(
          next_id,
          'textDocument/references',
          {
            'textDocument' => {
              'uri' => uri,
            },
            'position' => {
              'line' => line,
              'character' => column,
            },
            'context' => {
              'includeDeclaration' => include_decl,
            },
          }
        ))
        json['result'].map { |loc| Location.from_json(loc) }
      end

      def symbols(query)
        json = send(Request.new(
          next_id,
          'workspace/symbol',
          {
            'query' => query,
          }
        ))
        json['result'].map { |loc| DocumentSymbol.from_json(loc) }
      end

      def document_symbols(uri)
        json = send(Request.new(
          next_id,
          'textDocument/documentSymbol',
          {
            'textDocument' => {
              'uri' => uri,
            },
          }
        ))
        json['result'].map { |loc| DocumentSymbol.from_json(loc) }
      end

      def close
        send(Request.new(next_id, "shutdown", nil))
        @in.close
        @out.close
        @err.close
      end
    end
  end
end
