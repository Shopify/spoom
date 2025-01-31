# typed: strict
# frozen_string_literal: true

require "base64"

module Spoom
  module Stubs
    class StubCheck
      extend T::Sig

      sig do
        params(
          id: Integer,
          nesting: T::Array[T.any(Prism::ClassNode, Prism::ModuleNode)],
          receiver_type: String,
          method_name: String,
          arg_types: T::Array[String],
          return_type: String,
        ).void
      end
      def initialize(id:, nesting:, receiver_type:, method_name:, arg_types:, return_type:)
        @id = id
        @nesting = nesting
        @receiver_type = receiver_type
        @method_name = method_name
        @arg_types = arg_types
        @return_type = return_type

        @printer = T.let(Printer.new(out: StringIO.new), Printer)
      end

      sig { returns(String) }
      def snippet
        @printer.printl("# typed: strict")
        @printer.printl("# frozen_string_literal: true")
        @printer.printn

        @nesting.each do |node|
          kind = case node
          when Prism::ClassNode
            "class"
          when Prism::ModuleNode
            "module"
          end
          @printer.printl("#{kind} #{node.constant_path.slice}")
          @printer.indent
        end

        @printer.printl("extend T::Sig")
        @printer.printn

        @printer.printt
        @printer.print("sig { params(stub_recv: #{@receiver_type}")
        @arg_types.each_with_index do |type, i|
          @printer.print(", arg#{i}: #{type}")
        end
        @printer.print(").returns(#{@return_type}) }")
        @printer.printn

        @printer.printt
        @printer.print("def check_stub_#{@id}(stub_recv")
        @arg_types.each_with_index do |_type, i|
          @printer.print(", arg#{i}")
        end
        @printer.print(")")
        @printer.printn
        @printer.indent
        @printer.printt
        @printer.print("stub_recv.#{@method_name}(")
        @arg_types.each_with_index do |_type, i|
          @printer.print(", ") if i > 0
          @printer.print("arg#{i}")
        end
        @printer.print(")")
        @printer.printn
        @printer.dedent
        @printer.printt
        @printer.print("end")
        @printer.printn

        @nesting.each do |_node|
          @printer.dedent
          @printer.printl("end")
        end

        T.cast(@printer.out, StringIO).string
      end

      private

      sig { returns(T.nilable(String)) }
      def scope
        last = @nesting.last
        return unless last

        kind = case last
        when Prism::ClassNode
          "class"
        when Prism::ModuleNode
          "module"
        end

        namespace = []
        @nesting.each do |node|
          case node
          when Prism::ClassNode, Prism::ModuleNode
            name = node.constant_path.slice

            namespace.clear if name.start_with?("::")
            namespace << name
          end
        end

        "#{kind} #{namespace.join("::")}\b"
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

      sig { params(stub: Call).void }
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

        stub_check = StubCheck.new(
          id: stub.object_id,
          nesting: stub.nesting,
          receiver_type: recv_node,
          method_name: method_name,
          arg_types: arg_types,
          return_type: returns_type,
        )
        snippet = stub_check.snippet

        puts snippet
        send_snippet(stub, snippet)

        # diagnostics = pull_diagnostics
        # diagnostics.each do |diagnostic|
        #   next if with_nodes.empty? && diagnostic.code == 7004

        #   errors << StubError.new(diagnostic.message, diagnostic.code)
        #   # say_error("#{diagnostic.message} (#{diagnostic.code})")
        # end
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
