# typed: strict
# frozen_string_literal: true

require "json"

module Spoom
  module LSP
    class Client
      extend T::Sig

      class Error < Spoom::Error; end

      sig { params(command: String, args: T.untyped, chdir: String).void }
      def initialize(command, *args, chdir: ".")
        @command = command
        @request_id = T.let(0, Integer)

        stdin, stdout, stderr, wait_thread = T.unsafe(Open3).popen3(command, *args, chdir: chdir)
        @stdin = T.let(stdin, IO)
        @stdout = T.let(stdout, IO)
        @stderr = T.let(stderr, IO)
        @wait_thread = T.let(wait_thread, Thread)

        @response_handlers = T.let({}, T::Hash[Integer, T.proc.params(response: T.untyped).void])
        @diagnostic_handlers = T.let([], T::Array[T.proc.params(diagnostics: T.untyped).void])

        # Start reading responses in a separate thread
        @reader_thread = T.let(Thread.new { read_responses }, Thread)

        # Start reading stderr in a separate thread
        @error_thread = T.let(
          Thread.new do
            while (line = @stderr.gets)
              next if line == "Pausing\n"
              next if line == "Resuming\n"

              $stderr.puts(line)
            end
          end,
          Thread,
        )
      end

      # Send a request to the LSP server and wait for response
      sig { params(method: String, params: T.nilable(T::Hash[Symbol, T.untyped])).returns(T.untyped) }
      def request(method, params = nil)
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
      sig { params(method: String, params: T::Hash[Symbol, T.untyped]).void }
      def notify(method, params = {})
        message = {
          jsonrpc: "2.0",
          method: method,
          params: params,
        }
        send_message(message)
      end

      # Register a handler for diagnostic notifications
      sig { params(block: T.proc.params(diagnostics: T.untyped).void).void }
      def on_diagnostics(&block)
        @diagnostic_handlers << block
      end

      sig { void }
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

      sig { returns(Integer) }
      def next_request_id
        @request_id += 1
      end

      sig { params(message: T::Hash[T.untyped, T.untyped]).void }
      def send_message(message)
        json = message.to_json
        headers = "Content-Length: #{json.bytesize}\r\n\r\n"
        @stdin.write(headers + json)
        @stdin.flush
      end

      sig { void }
      def read_responses
        loop do
          # Read headers
          header = @stdout.gets("\r\n\r\n")
          break unless header

          content_length = header.match(/Content-Length: (\d+)/i)&.[](1)&.to_i
          next unless content_length

          # Read message body
          body = @stdout.read(content_length)
          next unless body

          message = JSON.parse(body)

          handle_message(message)
        end
      rescue IOError, Errno::EPIPE
        # Server connection closed
      end

      sig { params(message: T::Hash[T.untyped, T.untyped]).void }
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
end
