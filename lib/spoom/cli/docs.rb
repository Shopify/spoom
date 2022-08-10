# typed: true
# frozen_string_literal: true

require_relative "../model/model"
require_relative "../docs/index"
require_relative "../docs/html_symbol_printer"
require "benchmark"

module Spoom
  module Cli
    class Docs < Thor
      extend T::Sig
      include Helper

      default_task :docs

      desc "docs", "TODO"
      def docs
        in_sorbet_project!

        path = exec_path
        client = Spoom::LSP::Client.new(
          Spoom::Sorbet::BIN_PATH,
          "--lsp",
          "--enable-all-experimental-lsp-features",
          "--disable-watchman",
          path: path
        )
        client.open(File.expand_path(path))

        # Build file tree from project
        config = sorbet_config
        files = Spoom::Sorbet.srb_files(config, path: path)
        # files = files.reject { |file| file.end_with?(".rbi") }

        if files.empty?
          say_error("No file matching `#{sorbet_config_file}`")
          exit(1)
        end

        model = Spoom::Model.new

        print("Building model...")
        time = Benchmark.realtime do
          model = Spoom::Model::Builder::LSP.build_model(exec_path, client, files)
        end
        print("Done (#{time.round(2)}s)\n")


        print("Building index...  ")
        time = Benchmark.realtime do
          index = Spoom::Docs::Index.new(model)
          FileUtils.mkdir_p("docs")
          File.write("docs/index.html", index.to_html)
        end
        print("Done (#{time.round(2)}s)\n")

        # model.files.each do |file|
        #   puts file
        #   uri = to_uri(file)
        #   output_file = "docs/#{file}.html"
        #   output_dir = File.dirname(output_file)
        #   FileUtils.mkdir_p(output_dir)

        #   output_html = String.new
        #   symbols = client.document_symbols(uri)

        #   symbol_printer = Spoom::Docs::HTMLSymbolPrinter.new(
        #     client,
        #     uri,
        #     output_html
        #   )

        #   symbol_printer.visit_symbols(symbols)
        #   File.write(output_file, output_html)
        # end

        # tree = FileTree.new(files, strip_prefix: path)
        # client.

        # TODO get full symbol tree
        # TODO get documentation for symbols
      end

      no_commands do
        def to_uri(path)
          "file://" + File.join(File.expand_path(exec_path), path)
        end
      end
    end
  end
end
