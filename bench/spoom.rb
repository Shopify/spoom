# typed: true
# frozen_string_literal: true

require_relative "base"
require "spoom"

unless ARGV.first
  puts "Usage: ruby test.rb <path>"
  exit 1
end

files = time_it do
  list_files(ARGV.first)
end

time_it do
  puts "\n# Building model... (spoom)\n\n"

  model = Spoom::Model.new
  files.each do |file|
    builder = Spoom::Model::Builder.new(model, file)
    builder.visit(Spoom.parse_ruby(File.read(file), file: file, comments: true))
  end

  declarations = model.symbols.values
  puts "Declarations: #{declarations.size}"
  # declaration = declarations.first #: as !nil

  # puts declaration.inspect
  # puts declaration.full_name

  # definitions = declaration.definitions
  # definition = definitions.first #: as !nil

  # puts definition.inspect
  # puts definition.class
  # puts definition.full_name
  # puts definition.location
end
