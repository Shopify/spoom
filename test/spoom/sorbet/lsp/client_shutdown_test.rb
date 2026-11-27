# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module LSP
    class ClientShutdownTest < Minitest::Test
      # Rejects `shutdown` with params, as Sorbet does
      SERVER = <<~'RUBY'
        require "json"

        $stdin.binmode
        $stdout.binmode

        while (header = $stdin.gets("\r\n\r\n"))
          length = header[/Content-Length: ?(\d+)\r\n\r\n\z/, 1] or next
          message = JSON.parse($stdin.read(Integer(length)))
          response = if message.key?("params")
            { id: message["id"], error: { code: -32602, message: "shutdown takes no params" } }
          else
            { id: message["id"], result: nil }
          end
          json = JSON.generate(response)
          $stdout.write("Content-Length: #{json.bytesize}\r\n\r\n#{json}")
          $stdout.flush
        end
      RUBY

      def test_close_sends_shutdown_without_params
        Client.new(RbConfig.ruby, "-e", SERVER).close
      end
    end
  end
end
