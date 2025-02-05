# typed: true
# frozen_string_literal: true

require "json"
require "open3"

module Spoom
  class LSPClient
    class Error < StandardError; end

    def initialize(command, *args)
      @command = command
      @request_id = 0
      @stdin, @stdout, @stderr, @wait_thread = T.unsafe(Open3).popen3(command, *args)
      @response_handlers = {}
      @diagnostic_handlers = []

      # Start reading responses in a separate thread
      @reader_thread = Thread.new { read_responses }

      # Start reading stderr in a separate thread
      @error_thread = Thread.new do
        while (line = @stderr.gets)
          next if line == "Pausing\n"
          next if line == "Resuming\n"

          $stderr.puts(line)
        end
      end
    end

    # Send a request to the LSP server and wait for response\
    def request(method, params = {})
      id = next_request_id
      message = {
        jsonrpc: "2.0",
        id: id,
        method: method,
        params: params,
      }

      response = T.let(nil, T.untyped)
      mutex = Mutex.new
      condition = ConditionVariable.new

      @response_handlers[id] = lambda do |resp|
        mutex.synchronize do
          response = resp
          condition.signal
        end
      end

      send_message(message)

      # Wait for response with timeout
      mutex.synchronize do
        condition.wait(mutex, 100) # 30 second timeout
      end

      raise Error, "Request timed out" unless response

      response
    end

    # Send a notification to the LSP server (no response expected)
    def notify(method, params = {})
      message = {
        jsonrpc: "2.0",
        method: method,
        params: params,
      }
      send_message(message)
    end

    # Register a handler for diagnostic notifications
    def on_diagnostics(&block)
      @diagnostic_handlers << block
    end

    def shutdown
      request("shutdown")
      notify("exit")
      @reader_thread.kill
      @error_thread.kill
      @stdin.close
      @stdout.close
      @stderr.close
      @wait_thread.kill
    end

    private

    def next_request_id
      @request_id += 1
    end

    def send_message(message)
      json = message.to_json
      headers = "Content-Length: #{json.bytesize}\r\n\r\n"
      @stdin.write(headers + json)
      @stdin.flush
    end

    def read_responses
      loop do
        # Read headers
        header = @stdout.gets("\r\n\r\n")
        break unless header

        content_length = header.match(/Content-Length: (\d+)/i)&.[](1)&.to_i
        next unless content_length

        # Read message body
        body = @stdout.read(content_length)
        message = JSON.parse(body)

        handle_message(message)
      end
    rescue IOError, Errno::EPIPE
      # Server connection closed
    end

    def handle_message(message)
      if message["method"] == "textDocument/publishDiagnostics"
        @diagnostic_handlers.each { |handler| handler.call(message["params"]) }
      elsif message["id"]
        # Handle response to a request
        handler = @response_handlers.delete(message["id"])
        handler&.call(message["result"])
      end
    end
  end
end
