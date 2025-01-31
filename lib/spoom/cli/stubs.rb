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

        stubs_ids = T.let({}, T::Hash[Integer, Spoom::Stubs::Call])

        lsp_client.on_diagnostics do |diagnostic|
          # puts diagnostic["uri"]
          # diagnostic["diagnostics"].each do |d|
          #   puts "#{diagnostic["uri"]}:#{d["range"]["start"]["line"]}: #{d["message"]}"
          # end

          stub = T.must(stubs_ids[diagnostic["uri"].split("/").last.to_i])
          say_error("Stub `#{stub.location}` has errors:")
          diagnostic["diagnostics"].each do |error|
            warn("         * #{highlight(error["message"])} (#{error["code"]})")
          end
        end

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

        say("Collecting files...")
        files = collect_files([path])
        files = files.select { |file| file.end_with?("_test.rb") }
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

        say("Checking `#{stubs.size}` stubs...")
        checker = Spoom::Stubs::Checker.new(File.expand_path(path), lsp_client, 4)
        stubs.each_with_index do |stub, index|
          stubs_ids[stub.object_id] = stub

          say("Checking stub `#{index + 1}/#{stubs.size}`") if index % 100 == 0

          errors = checker.check(stub)
          next if errors.empty?

          file = "#{path}/#{stub.location.file}"
          say_error("Stub `#{file}:#{stub.location.start_line}` has errors:")
          errors.each do |error|
            warn("         * #{highlight(error.message)} (#{error.code})")
          end
          warn("\n")
        end
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

          if files.empty?
            say_error("No files to transform")
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

# TODO: collect namespaces
# TODO: create check file
# TODO: run typechecking
# TODO: collect diagnostics
# TODO: print diagnostics
