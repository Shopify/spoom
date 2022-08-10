# typed: true
# frozen_string_literal: true

require_relative "../model/model"
require_relative "../docs/template"

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

        config = sorbet_config
        files = Spoom::Sorbet.srb_files(config, path: path)

        if files.empty?
          say_error("No file matching `#{sorbet_config_file}`")
          exit(1)
        end

        model = Spoom::Model.new

        print("Building model...")
        time = Benchmark.realtime do
          model = Spoom::Model::Builder::LSP.build_model(exec_path, client, files)
        end
        print(" Done (#{time.round(2)}s)\n")

        FileUtils.mkdir_p("docs")

        print("Building index...")
        time = Benchmark.realtime do
          page = Spoom::Docs::Templates::Page.new(
            Spoom::Docs::Templates::Pages::Index.new(model)
          )
          page.write!("docs/index.html")
        end
        print(" Done (#{time.round(2)}s)\n")

        # print("Building file pages...")
        # time = Benchmark.realtime do
        #   model.files.sort.each do |_path, file|
        #     page = Spoom::Docs::Templates::Page.new(
        #       Spoom::Docs::Templates::Pages::FileSymbols.new(file)
        #     )
        #     page.write!("docs/files/#{file.path}.html")
        #   end
        # end
        # print(" Done (#{time.round(2)}s)\n")

        print("Building scopes pages...")
        time = Benchmark.realtime do
          model.scopes.sort.each do |fully_qualified_name, scopes|
            page = Spoom::Docs::Templates::Page.new(
              Spoom::Docs::Templates::Pages::Scope.new(fully_qualified_name, scopes)
            )
            page.write!( "docs/scopes/#{fully_qualified_name}.html")
          end
        end
        print(" Done (#{time.round(2)}s)\n")

        # TODO: handle links properly
      end
    end
  end
end
