# typed: true
# frozen_string_literal: true

require "spoom"

PROJECT_PATH = "/Users/andyw8/src/github.com/Shopify/code-db"

require "rbi"

class Visitor < RBI::Visitor
  extend T::Sig

  def initialize(file, client)
    @file = file
    @client = client
    super()
  end

  def visit_tree(node)
    visit_all(node.nodes)
  end

  sig { override.params(node: RBI::Module).void }
  def visit_module(node)
    # puts "module #{node.name}"
    loc = T.must(node.loc)
    result = refs(T.must(loc.begin_line) - 1, loc.begin_column + 8)
    if result.length <= 1
      puts "DEAD: #{node.name}"
    end
    # visit_tree(node.body)
  end

  private

  def refs(line, col)
    @client.request(
      "textDocument/references",
      {
        textDocument: { uri: "file://" + File.expand_path(@file) },
        position: { line: line.to_i, character: col.to_i },
        context: { includeDeclaration: true },
      },
    )
  end

  def hover(line, col)
    @client.request(
      "textDocument/hover",
      {
        textDocument: { uri: "file://" + File.expand_path(@file) },
        position: { line: line.to_i, character: col.to_i },
      },
    )
  end
end

module Experiment
  extend T::Sig

  sig { returns(Spoom::LSP::Client) }
  def self.lsp_client # rubocop:disable Style/ClassMethodsDefinitions
    client = Spoom::LSP::Client.new(
      Spoom::Sorbet::BIN_PATH,
      "--lsp",
      "--enable-all-experimental-lsp-features",
      "--disable-watchman",
      # "-v",
      # "-v",
      chdir: PROJECT_PATH,
    )
    client.request("initialize", {
      rootPath: PROJECT_PATH,
      rootUri: "file://" + PROJECT_PATH,
      capabilities: {},
    })

    client.notify("initialized", {})
    client
  end
end

SHIM_PATH = PROJECT_PATH + "/sorbet/rbi/shims"

client = Experiment.lsp_client
Dir["#{SHIM_PATH}/**/*.rbi"].each do |path|
  node = RBI::Parser.parse_file(path)
  visitor = Visitor.new(path, client)
  visitor.visit(node)
end

# sleep 20
# client.shutdown

exit

class Foo
end

class Spoom::LSP::Client # rubocop:disable Style/ClassAndModuleChildren
end

client = Experiment.lsp_client
client.on_diagnostics do |diagnostics|
  puts diagnostics.inspect
end

path = "/Users/andyw8/src/github.com/Shopify/code-db"

res = client.request(
  "textDocument/hover",
  {
    textDocument: { uri: "file://" + PROJECT_PATH + "/app/models/user.rb" },
    position: { line: 3, character: 7 },
  },
)
# puts res.inspect

# puts refs(client, "experiment.rb", 21, 7).inspect
# puts refs(client, "experiment.rb", 24, 7).inspect
