# typed: true
# frozen_string_literal: true

require "index"

unless ARGV.first
  puts "Usage: ruby index.rb <path>"
  exit 1
end

puts "\n# Building graph... (index)\n\n"

path = File.absolute_path(ARGV.first)

graph = Index::Graph.new
graph.index_all([path])

declaration = graph["Spoom::Model::Builder"]
puts declaration.name

declaration.definitions.each do |definition|
  puts definition.kind
  puts definition.uri
  puts definition.location
end
