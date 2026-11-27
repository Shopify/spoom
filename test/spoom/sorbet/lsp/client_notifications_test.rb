# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module LSP
    class ClientNotificationsTest < Minitest::Test
      # Sends a `window/showMessage` notification before each response, as Sorbet does on `# typed: false` files
      SERVER = <<~'RUBY'
        require "json"

        $stdin.binmode
        $stdout.binmode

        def write(message)
          json = JSON.generate(message)
          $stdout.write("Content-Length: #{json.bytesize}\r\n\r\n#{json}")
          $stdout.flush
        end

        while (header = $stdin.gets("\r\n\r\n"))
          length = header[/Content-Length: ?(\d+)\r\n\r\n\z/, 1] or next
          message = JSON.parse($stdin.read(Integer(length)))
          write(method: "window/showMessage", params: { type: 3, message: "hello" })
          write(id: message["id"], result: message["params"])
        end
      RUBY

      def test_skips_notifications_until_the_response
        client = Client.new(RbConfig.ruby, "-e", SERVER)

        2.times do |n|
          request = Request.new(client.next_id, "echo", { "n" => n })

          assert_equal(request.params, client.send(request)&.dig("result"))
        end
      end
    end
  end
end
