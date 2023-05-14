# typed: true
# frozen_string_literal: true

require "spoom"
require "spoom/model/generator"
require "spoom/model/index"
require "spoom/model/index_array"
require "spoom/model/index_list"

def time(&block)
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  res = block.call
  t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts "=> #{t1 - t0}s"
  res
end

context = Spoom::Context.mktmp!

time do
  puts "Generating files..."
  generator = Spoom::Model::Generator.new
  generator.generate_files(context, 100)
  puts "Generated #{generator.generated_classes} classes"
end

puts "\n# With linked lists\n\n"

index = Spoom::Model::IndexList.new
indexer = Spoom::Model::Indexer.new(index)

time do
  puts "Indexing files..."
  context.glob("**/*.rb").each do |file|
    ruby = context.read(file)
    indexer.index_string(ruby, path: file)
  end
  puts "Indexed #{index.entries.to_a.size} entries (#{index.names.to_a.size} unique names)"
end

time do
  puts "Deleting files..."
  context.glob("**/*.rb").each do |file|
    index.delete_names_with_path(file)
  end
  puts "Indexed #{index.entries.to_a.size} entries (#{index.names.to_a.size} unique names)"
end

puts "\n# With arrays\n\n"

index = Spoom::Model::IndexArray.new
indexer = Spoom::Model::Indexer.new(index)

time do
  puts "Indexing files..."
  context.glob("**/*.rb").each do |file|
    ruby = context.read(file)
    indexer.index_string(ruby, path: file)
  end
  puts "Indexed #{index.entries.to_a.size} entries (#{index.names.to_a.size} unique names)"
end

time do
  puts "Deleting files..."
  context.glob("**/*.rb").each do |file|
    index.delete_names_with_path(file)
  end
  puts "Indexed #{index.entries.to_a.size} entries (#{index.names.to_a.size} unique names)"
end

context.destroy!

# TODO: generate files in context
# TODO: parse & index model
# TODO: delete all files
# TODO: monitor times for each
# TODO: monitor peak memory
