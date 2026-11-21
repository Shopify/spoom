# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module LSP
    class ClientFramingTest < Minitest::Test
      # Accepts only spec-exact framing and answers each request with its params
      SERVER = <<~'RUBY'
        require "json"

        $stdin.binmode
        $stdout.binmode

        while (header = $stdin.gets("\r\n\r\n"))
          length = header[/\AContent-Length: (\d+)\r\n\r\n\z/, 1] or abort("bad header: #{header.inspect}")
          message = JSON.parse($stdin.read(Integer(length)))
          json = JSON.generate(id: message["id"], result: message["params"])
          $stdout.write("Content-Length: #{json.bytesize}\r\n\r\n#{json}")
          $stdout.flush
        end
      RUBY

      def test_frames_non_ascii_messages_by_byte_length
        client = Client.new(RbConfig.ruby, "-e", SERVER)
        params = { "query" => "Café ☕" }

        # The second request catches any bytes left over from the first
        2.times do
          assert_equal(params, client.send(Request.new(client.next_id, "echo", params))&.dig("result"))
        end
      end
    end
  end
end
