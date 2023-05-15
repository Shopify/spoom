# typed: true
# frozen_string_literal: true

require "spoom"
require "spoom/model/generator"
require "spoom/model/index"
require "spoom/model/index_array"
require "spoom/model/index_list"
require "spoom/model/index_set"

def time(&block)
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  block.call
  t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  t1 - t0
end

[10, 100].each do |files|
  context = Spoom::Context.mktmp!

  puts "# #{files} files"
  generator = Spoom::Model::Generator.new
  generator.generate_files(context, files)

  puts " ## Parsing"
  parsed = context.glob("**/*.rb").map do |file|
    ruby = context.read(file)
    [file, Spoom::Model::Parser.parse_string(ruby)]
  end

  index_classes = T.let([
    Spoom::Model::IndexSet,
    Spoom::Model::IndexList,
    Spoom::Model::IndexArray,
  ], T::Array[T.class_of(Spoom::Model::Index)])

  index_classes.each do |index_class|
    puts " ## #{index_class}"

    index = index_class.new
    indexer = Spoom::Model::Indexer.new(index)

    puts "    Indexing files..."
    indexing_time = time do
      parsed.each do |(file, node)|
        indexer.index(node, file: file)
      end
    end
    puts "    Indexed #{index.entries.to_a.size} entries (#{index.names.to_a.size} unique names) in #{indexing_time}s"

    puts "    Deleting files..."
    deleting_time = time do
      context.glob("**/*.rb").each do |file|
        index.delete_names_with_path(file)
      end
    end
    puts "    Indexed #{index.entries.to_a.size} entries (#{index.names.to_a.size} unique names) in #{deleting_time}s"
  end

  context.destroy!
end

# TODO: monitor times for each
# TODO: monitor peak memory
