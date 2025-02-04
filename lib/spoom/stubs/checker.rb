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
          location: Location,
          nesting: T::Array[T.any(Prism::ClassNode, Prism::ModuleNode)],
          receiver_type: String,
          method_name: String,
          arg_types: T::Array[String],
          return_type: T.nilable(String),
          any_instance: T::Boolean,
          with_location: T::Boolean,
        ).void
      end
      def initialize(id:, location:, nesting:, receiver_type:, method_name:, arg_types:, return_type:, any_instance:,
        with_location: true)
        @id = id
        @location = location
        @nesting = nesting
        @receiver_type = receiver_type
        @method_name = method_name
        @arg_types = arg_types
        @return_type = return_type
        @any_instance = any_instance
        @printer = T.let(Printer.new(out: StringIO.new), Printer)
        @with_location = with_location
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

        @printer.printl("# Test for #{@location}") if @with_location
        @printer.printt
        @printer.print("sig { params(recv: ")
        if @any_instance
          @printer.print(@receiver_type)
        else
          @printer.print("T.class_of(#{@receiver_type})")
        end
        @arg_types.each_with_index do |type, i|
          @printer.print(", arg#{i + 1}: #{type}")
        end
        @printer.print(", ret: #{@return_type}") if @return_type
        @printer.print(").void }")
        @printer.printn

        @printer.printt
        @printer.print("def check_stub_#{@id}(recv")
        @arg_types.each_with_index do |_type, i|
          @printer.print(", arg#{i + 1}")
        end
        @printer.print(", ret") if @return_type
        @printer.print(")")
        @printer.printn
        @printer.indent
        @printer.printt
        @printer.print("res = ") if @return_type
        @printer.print("recv.#{@method_name}(")
        @arg_types.each_with_index do |_type, i|
          @printer.print(", ") if i > 0
          @printer.print("arg#{i + 1}")
        end
        @printer.print(")")
        if @return_type
          @printer.printn
          @printer.printt
          @printer.print("[].each { res = ret }")
        end
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

      sig { params(root_dir: String, lsp_client: LSPClient, with_location: T::Boolean).void }
      def initialize(root_dir, lsp_client, with_location: true)
        @root_dir = root_dir
        @lsp_client = lsp_client
        @with_location = with_location
      end

      sig { params(stub: Call).returns(T.nilable(String)) }
      def generate_snippet(stub)
        receiver_node = stub.receiver_node
        recv_node = case receiver_node
        when Prism::ConstantReadNode, Prism::ConstantPathNode
          receiver_node.slice
        end

        unless recv_node
          say_error("No receiver node for stub at #{stub.location}")
          return
        end

        expect_node = stub.expects_node
        unless expect_node.is_a?(Prism::SymbolNode)
          say_error("Expects node is not a symbol for stub at #{stub.location}")
          return
        end
        method_name = expect_node.slice.delete_prefix(":")

        returns_node = stub.returns_node
        unless returns_node
          say_error("No returns node for stub at #{stub.location}")
          return
        end

        arg_types = stub.with_nodes.map do |with_node|
          node_type(with_node, stub.location)
        end.compact

        returns_type = node_type(returns_node, stub.location)
        unless returns_type
          say_error("Failed to get returns type for stub at #{stub.location}")
          return
        end

        case returns_type
        when "T.untyped", "Mocha::Mock"
          returns_type = nil
        end

        stub_check = StubCheck.new(
          id: stub.object_id,
          location: stub.location,
          nesting: stub.nesting,
          receiver_type: recv_node,
          method_name: method_name,
          arg_types: arg_types,
          return_type: returns_type,
          any_instance: stub.any_instance,
          with_location: @with_location,
        )
        snippet = stub_check.snippet

        # puts snippet
        # send_snippet(stub, snippet)

        # diagnostics = pull_diagnostics
        # diagnostics.each do |diagnostic|
        #   next if with_nodes.empty? && diagnostic.code == 7004

        #   errors << StubError.new(diagnostic.message, diagnostic.code)
        #   # say_error("#{diagnostic.message} (#{diagnostic.code})")
        # end

        snippet
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
        when /String(.*)/
          "String"
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
