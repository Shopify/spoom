# typed: strict
# frozen_string_literal: true

require "base64"

module Spoom
  module Stubs
    class StubError
      extend T::Sig

      sig { returns(String) }
      attr_reader :message

      sig { returns(Integer) }
      attr_reader :code

      sig { params(message: String, code: Integer).void }
      def initialize(message, code)
        @message = message
        @code = code
      end
    end

    class Checker
      extend T::Sig
      include Colorize

      sig { params(root_dir: String, lsp_client: LSP::Client, request_id: Integer).void }
      def initialize(root_dir, lsp_client, request_id)
        @root_dir = root_dir
        @lsp_client = lsp_client
        @request_id = request_id
      end

      sig { params(stub: Call).returns(T::Array[StubError]) }
      def check(stub)
        recv_node = stub.receiver_node&.slice
        unless recv_node
          say_error("No receiver node for stub at #{stub.location}")
          return []
        end

        method_name = stub.expects_node&.slice&.delete_prefix(":")
        unless method_name
          say_error("No method name for stub at #{stub.location}")
          return []
        end

        returns_location = stub.returns_location
        unless returns_location
          say_error("No returns node for stub at #{stub.location}")
          return []
        end

        returns_type = hover_type(returns_location)
        unless returns_type
          say_error("Failed to get returns type for stub at #{stub.location}")
          return []
        end
        returns_type = transform_type(returns_type)

        with_nodes = stub.with_nodes.map(&:slice)

        snippet = build_snippet(recv_node, method_name, with_nodes, returns_type)
        send_snippet(snippet)

        errors = []

        diagnostics = pull_diagnostics
        diagnostics.each do |diagnostic|
          next if with_nodes.empty? && diagnostic.code == 7004

          errors << StubError.new(diagnostic.message, diagnostic.code)
          # say_error("#{diagnostic.message} (#{diagnostic.code})")
        end

        errors
      end

      private

      sig { params(location: Location).returns(T.nilable(String)) }
      def hover_type(location)
        res = @lsp_client.send(
          Spoom::LSP::Request.new(
            @request_id += 1,
            "textDocument/hover",
            {
              "textDocument" => {
                "uri" => to_uri(location.file),
              },
              "position" => {
                "line" => T.must(location.start_line) - 1,
                "character" => T.must(location.start_column),
              },
            },
          ),
        )

        res&.dig("result", "contents", "value")
      rescue Spoom::LSP::Error::Diagnostics => err
        say_error("Failed to get returns type for stub at #{location}: #{err.message}")
        err.diagnostics.each do |diagnostic|
          say_error("  #{diagnostic.message} (#{diagnostic.code})")
        end
        nil
      end

      sig { params(type: String).returns(String) }
      def transform_type(type)
        case type
        when "TrueClass", "FalseClass"
          "T::Boolean"
        when /T.class_of\((.*)\)/
          T.must(Regexp.last_match(1))
        else
          type
        end
      end

      sig { params(snippet: String).void }
      def send_snippet(snippet)
        @lsp_client.send(
          Spoom::LSP::Notification.new(
            "textDocument/didOpen",
            {
              "textDocument" => {
                "uri" => to_uri("tmp_app/_mock.rb"),
                "languageId" => "ruby",
                "version" => 1,
                "text" => snippet,
              },
            },
          ),
        )
      end

      sig { returns(T::Array[Spoom::LSP::Diagnostic]) }
      def pull_diagnostics
        @lsp_client.read
        []
      rescue Spoom::LSP::Error::Diagnostics => err
        err.diagnostics
      end

      sig do
        params(
          receiver_type: String,
          method_name: String,
          params: T::Array[String],
          return_type: String,
        ).returns(String)
      end
      def build_snippet(receiver_type, method_name, params, return_type)
        <<~RUBY
          # typed: strict
          # frozen_string_literal: true

          extend T::Sig

          sig { params(stub_recv: #{receiver_type}).returns(#{return_type}) }
          def check_stub(stub_recv)
            stub_recv.#{method_name}(#{params.join(", ")})
          end
        RUBY
      end

      sig { params(path: String).returns(String) }
      def to_uri(path)
        "file://" + File.join(File.expand_path(@root_dir), path)
      end

      sig { params(message: String).void }
      def say_error(message)
        warn("#{set_color("Error", Color::RED)}: #{message}")
      end
    end
  end
end
