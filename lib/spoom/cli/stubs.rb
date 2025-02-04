# typed: true
# frozen_string_literal: true

require_relative "../lsp_client"
require_relative "../stubs"

module Spoom
  module Cli
    class Counter
      extend T::Sig

      sig { returns(T::Hash[String, Integer]) }
      attr_reader :values

      sig { void }
      def initialize
        @values = T.let({}, T::Hash[String, Integer])
      end

      sig { params(value: String).void }
      def increment(value)
        @values[value] = @values[value].to_i + 1
      end

      sig { params(value: String).returns(Integer) }
      def [](value)
        @values[value] || 0
      end

      sig { returns(Integer) }
      def total
        @values.values.sum
      end

      sig { void }
      def print
        @values.sort_by { |_, count| -count }.each do |value, count|
          puts "#{value}: #{count} (#{(count / total.to_f * 100).round(2)}%)"
        end
        puts "\nTotal: #{total}"
      end
    end

    class Stubs < Thor
      extend T::Sig
      include Helper

      default_task :check

      desc "check PATH", "Check stubs in PATH"
      sig { params(path: String).void }
      def check(path = ".")
        say("Collecting files...")
        files = collect_files([path])
        say("Collected `#{files.size}` files")

        say("Collecting stubs...")
        stubs = T.let([], T::Array[Spoom::Stubs::Call])
        files.each do |file|
          ruby = File.read(file)
          node = Spoom.parse_ruby(ruby, file: file)

          # file = file.delete_prefix(path)
          visitor = Spoom::Stubs::Collector.new(file)
          visitor.visit(node)

          stubs.concat(visitor.stubs)
        end
        say("Collected `#{stubs.size}` stubs")

        say("Starting LSP client...")
        lsp_client = Spoom::LSPClient.new(
          Spoom::Sorbet::BIN_PATH,
          "--lsp",
          # "--enable-all-experimental-lsp-features",
          "--disable-watchman",
          # "--debug-log-file=lsp.log",
          # "-v",
          # "-v",
          # "-v",
        )

        lsp_client.request("initialize", {
          rootPath: File.expand_path(path),
          rootUri: "file://#{File.expand_path(path)}",
          capabilities: {},
        })

        lsp_client.notify("initialized", {})
        say("Started LSP client")

        # say("Starting LSP client...")
        # lsp_client = T.let(self.lsp_client(path), Spoom::LSP::Client)
        # say("Started LSP client")

        # puts lsp_client.request(
        #   "textDocument/hover",
        #   {
        #     textDocument: { uri: "file:///#{File.expand_path(path)}/lib/spoom/cli/stubs.rb" },
        #     position: { line: 137, character: 31 },
        #   },
        # )

        # lsp_client.hover(
        #   to_uri(
        #     path,
        #     "components/access_and_auth/customer_auth_identity/test/controllers/access_and_auth/customer_auth_identity/concerns/callback_handler_test.rb",
        #   ),
        #   358,
        #   19,
        # )
        # return

        say("Checking `#{stubs.size}` stubs...")
        FileUtils.rm_rf("_mock_test_snippets")
        FileUtils.mkdir_p("_mock_test_snippets")

        stubs_snippets = T.let({}, T::Hash[String, Spoom::Stubs::Call])

        checker = Spoom::Stubs::Checker.new(File.expand_path(path), lsp_client)
        stubs.each_with_index do |stub, index|
          # stubs_ids[stub.object_id] = stub

          say("Generating snippet for stub `#{index + 1}/#{stubs.size}`") if index % 100 == 0

          snippet = checker.generate_snippet(stub)
          filename = "_mock_test_snippets/#{stub.object_id}.rb"
          File.write(filename, snippet)
          stubs_snippets[filename] = stub
        end

        say("Generated `#{stubs.size}` snippets")

        say("Running type checking...")

        error_url_base = Spoom::Sorbet::Errors::DEFAULT_ERROR_URL_BASE
        result = T.unsafe(context).srb_tc(
          "--error-url-base=#{error_url_base}",
          sorbet_bin: Spoom::Sorbet::BIN_PATH,
          capture_err: true,
        )

        errors = Spoom::Sorbet::Errors::Parser.parse_string(result.err, error_url_base: error_url_base)

        stub_errors = T.let({}, T::Hash[String, T::Array[String]])

        errors.sort.each do |error|
          stub = stubs_snippets[T.must(error.file)]
          next unless stub
          # say_error("Stub `#{stub.location}` has errors:")
          # say_error("         * #{highlight(T.must(error.message))} (#{error.code})")

          next if error.code == 7004 && stub.with_nodes.empty?

          (stub_errors[stub.location.to_s] ||= []) << if error.code == 7001
            lines = error.more.join("\n")
            # puts lines
            expected_match = lines.match(/Existing variable has type: `(.*)`/)
            got_match = lines.match(/Attempting to change type to: `(.*)`/)

            next if expected_match.nil? || got_match.nil?

            expected = expected_match[1]
            got = got_match[1]

            "Incompatible return type, expected `#{expected}`, got `#{got}`"
          else
            T.must(error.message) + " (#{error.file})"
          end
        end

        stub_errors.each do |stub_location, errors|
          say_error("Stub `#{stub_location}` has errors:")
          errors.each do |error|
            warn("         * #{highlight(error)}")
          end
        end

        say("Found `#{stub_errors.size}` errors")
      end

      no_commands do
        def collect_files(paths)
          paths << "." if paths.empty?

          files = paths.flat_map do |path|
            if File.file?(path)
              [path]
            else
              Dir.glob("#{path}/**/*.rb")
            end
          end

          files.select! { |file| file.end_with?("_test.rb") }

          if files.empty?
            say_error("No test files to check")
            exit(1)
          end

          files
        end

        def literal?(node)
          case node
          when Prism::TrueNode, Prism::FalseNode,
               Prism::NilNode,
               Prism::IntegerNode, Prism::FloatNode,
               Prism::StringNode, Prism::SymbolNode, Prism::InterpolatedStringNode,
               Prism::ArrayNode, Prism::HashNode, Prism::KeywordHashNode,
               Prism::ConstantPathNode, Prism::ConstantReadNode
            true
          else
            false
          end
        end

        def lsp_client(path)
          context_requiring_sorbet!

          client = Spoom::LSP::Client.new(
            # "/Users/at/src/github.com/sorbet/sorbet/bazel-bin/main/sorbet",
            Spoom::Sorbet::BIN_PATH,
            "--lsp",
            # "--no-config",
            # "--enable-all-experimental-lsp-features",
            "--disable-watchman",
            # "--debug-log-file=lsp.log",
            # ".",
            # "-v",
            # "-v",
            # "-v",
            path: path,
          )
          client.open(File.expand_path(path))
          client
        end

        def to_uri(root_path, path)
          "file://" + File.join(File.expand_path(root_path), path)
        end
      end
    end
  end
end

# TODO: create check file
# TODO: run typechecking
# TODO: collect diagnostics
# TODO: print diagnostics
#   TODO: reject error Mocha::Mock
#   TODO: reject error T.untyped
