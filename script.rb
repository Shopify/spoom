# typed: true
# frozen_string_literal: true

require "spoom"

# Collect all the files
warn "Collecting files..."
files = ARGV.flat_map do |path|
  if File.directory?(path)
    Dir.glob(File.join(path, "**/*.rb")).sort
  else
    path
  end
end
warn "  Collected #{files.size} files"

# Build the model
warn "Building the model..."
model = Spoom::Model.new

files.each do |file|
  content = File.read(file)
  node = Spoom.parse_ruby(content, file: file)
  builder = Spoom::Model::Builder.new(model, file)
  builder.visit(node)
rescue Spoom::ParseError
  # no-op
end
warn "  Found #{model.symbols.size} symbols"

# Collect all the references
warn "Collecting references..."
refs = T.let({}, T::Hash[String, T::Array[Spoom::Model::Reference]])
files.each do |file|
  content = File.read(file)
  node = Spoom.parse_ruby(content, file: file)
  visitor = Spoom::Model::ReferencesVisitor.new(file)
  visitor.visit(node)

  visitor.references.each do |ref|
    (refs[ref.name] ||= []) << ref
  end
rescue Spoom::ParseError
  # no-op
end
warn "  Found #{refs.size} references"

# Collect all subclasses of `ApplicationController`
warn "Collecting subclasses of ApplicationController..."
model.finalize!
symbol = model["ApplicationController"]
subclasses = model.subtypes(symbol)
warn "  Found #{subclasses.size} subclasses"
warn "\n\n"

puts "Subclasses of ApplicationController:"
subclasses.each do |subclass|
  puts "  #{subclass.name}"
  subclass.definitions.each do |defn|
    next unless defn.is_a?(Spoom::Model::Class)

    defn.children.each do |child|
      next unless child.is_a?(Spoom::Model::Method)
      next unless child.visibility == Spoom::Model::Visibility::Public

      puts "    #{child.name} - #{child.location} (#{refs[child.name]&.size || 0} refs)"
    end
  end
end
