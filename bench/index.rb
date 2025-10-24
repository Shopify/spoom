# typed: true
# frozen_string_literal: true

require "saturn"

unless ARGV.first
  puts "Usage: ruby index.rb <path>"
  exit 1
end

puts "\n# Building graph... (index)\n\n"

path = File.absolute_path(ARGV.first)

graph = Saturn::Graph.new
graph.index_all([path])

puts graph.declarations.size

declaration = graph["Shopify"]
puts declaration.name

puts "Definitions: #{declaration.definitions.size}"

declaration.definitions.each do |definition|
  puts definition.inspect
  puts definition.location
  puts definition.comments.map(&:string)
end
