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

    class StubCheck
      extend T::Sig

      sig do
        params(
          id: Integer,
          receiver_type: String,
          method_name: String,
          arg_types: T::Array[String],
          return_type: String,
        ).void
      end
      def initialize(id, receiver_type, method_name, arg_types, return_type)
        @id = id
        @receiver_type = receiver_type
        @method_name = method_name
        @arg_types = arg_types
        @return_type = return_type
      end

      sig { returns(String) }
      def signature
        sig = +"sig { params(stub_recv: #{@receiver_type}"
        @arg_types.each_with_index do |type, i|
          sig << ", arg#{i}: #{type}"
        end
        sig << ").returns(#{@return_type}) }"
        sig
      end

      sig { returns(String) }
      def definition
        rb = +"def check_stub_#{@id}(stub_recv"
        @arg_types.each_with_index do |_type, i|
          rb << ", arg#{i}"
        end
        rb << ")\n"
        rb << "  stub_recv.#{@method_name}(#{@arg_types.map.with_index { |_type, i| "arg#{i}" }.join(", ")})\n"
        rb << "end\n"
        rb
      end

      sig { returns(String) }
      def snippet
        <<~RUBY
          # typed: strict
          # frozen_string_literal: true

          extend T::Sig

          #{signature}
          #{definition}
        RUBY
      end
    end

    class Checker
      extend T::Sig
      include Colorize

      sig { params(root_dir: String, lsp_client: LSPClient, request_id: Integer).void }
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

        returns_node = stub.returns_node
        unless returns_node
          say_error("No returns node for stub at #{stub.location}")
          return []
        end

        arg_types = stub.with_nodes.map do |with_node|
          node_type(with_node, stub.location)
        end.compact

        returns_type = node_type(returns_node, stub.location)
        unless returns_type
          say_error("Failed to get returns type for stub at #{stub.location}")
          return []
        end

        stub_check = StubCheck.new(stub.object_id, recv_node, method_name, arg_types, returns_type)
        snippet = stub_check.snippet

        puts snippet
        send_snippet(stub, snippet)

        errors = []

        # diagnostics = pull_diagnostics
        # diagnostics.each do |diagnostic|
        #   next if with_nodes.empty? && diagnostic.code == 7004

        #   errors << StubError.new(diagnostic.message, diagnostic.code)
        #   # say_error("#{diagnostic.message} (#{diagnostic.code})")
        # end

        errors
      end

      private

      sig { params(node: Prism::Node, stub_location: Location).returns(T.nilable(String)) }
      def node_type(node, stub_location)
        returns_type = literal_type(node)

        unless returns_type
          returns_location = case node
          when Prism::CallNode
            message_location = node.message_loc

            if message_location
              Location.from_prism(stub_location.file, message_location)
            else
              Location.from_prism(stub_location.file, node.location)
            end
          else
            Location.from_prism(stub_location.file, node.location)
          end

          returns_type = hover_type(returns_location)
        end

        return unless returns_type

        transform_type(returns_type)
      end

      sig { params(node: Prism::Node).returns(T.nilable(String)) }
      def literal_type(node)
        case node
        when Prism::TrueNode, Prism::FalseNode
          "T::Boolean"
        when Prism::NilNode
          "NilClass"
        when Prism::StringNode, Prism::InterpolatedStringNode
          "String"
        when Prism::SymbolNode
          "Symbol"
        when Prism::IntegerNode
          "Integer"
        when Prism::FloatNode
          "Float"
        when Prism::ArrayNode
          "T::Array[T.untyped]"
        when Prism::HashNode, Prism::KeywordHashNode
          "T::Hash[T.untyped, T.untyped]"
        end
      end

      sig { params(location: Location).returns(T.nilable(String)) }
      def hover_type(location)
        res = @lsp_client.request(
          "textDocument/hover",
          {
            textDocument: {
              uri: to_uri(location.file),
            },
            position: {
              line: T.must(location.end_line) - 1,
              character: T.must(location.end_column) - 1,
            },
          },
        )

        res = T.let(res&.dig("contents", "value"), T.nilable(String))
        res&.split("# result type:\n")&.last&.lines&.first&.strip
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

      sig { params(stub: Call, snippet: String).void }
      def send_snippet(stub, snippet)
        @lsp_client.notify(
          "textDocument/didOpen",
          {
            textDocument: {
              uri: to_uri("__stub_check/#{stub.object_id}"),
              languageId: "ruby",
              version: 1,
              text: snippet,
            },
          },
        )
      end

      sig { params(stub: Call, snippet: String).void }
      def send_snippet2(stub, snippet)
        @lsp_client.notify(
          "textDocument/didChange",
          {
            textDocument: {
              uri: to_uri("__stub_check/#{stub.object_id}"),
              version: 1,
            },
            contentChanges: [
              {
                text: snippet,
              },
            ],
          },
        )
      end

      # sig { returns(T::Array[Spoom::LSP::Diagnostic]) }
      # def pull_diagnostics
      #   @lsp_client.read
      #   []
      # rescue Spoom::LSP::Error::Diagnostics => err
      #   err.diagnostics
      # end

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
        "file://" + File.expand_path(File.join(@root_dir, path))
      end

      sig { params(message: String).void }
      def say_error(message)
        warn("#{set_color("Error", Color::RED)}: #{message}")
      end
    end
  end
end
