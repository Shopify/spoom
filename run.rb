# typed: true
# frozen_string_literal: true

require "spoom"

path = ARGV[0]
unless path
  puts "Usage: #{$PROGRAM_NAME} <path>"
  exit 1
end

context = Spoom::Context.new(path)

$stderr.puts "Collecting files..."
collector = Spoom::FileCollector.new(
  allow_extensions: [".rb", ".erb", ".gemspec"],
  allow_mime_types: ["text/x-ruby", "text/x-ruby-script"],
  exclude_patterns: ["vendor/", "sorbet/", "tmp/"].map { |p| Pathname.new(File.join(path, p, "**")).cleanpath.to_s },
)

collector.visit_path(path)
files = collector.files.sort

plugins = (Spoom::Deadcode::DEFAULT_PLUGINS + Spoom::Deadcode::PLUGINS_FOR_GEM.values.uniq).map(&:new)
# plugins = Spoom::Deadcode.plugins_from_gemfile_lock(context)
$stderr.puts "Indexing #{files.size} files..."

index = Spoom::Deadcode::Index.new
files.each_with_index do |file, i|
  $stderr.print("#{i + 1}/#{files.size}\r")

  content = File.read(file)
  if file.end_with?(".erb")
    Spoom::Deadcode.index_erb(index, content, file: file, plugins: plugins)
  else
    Spoom::Deadcode.index_ruby(index, content, file: file, plugins: plugins)
  end
rescue Spoom::Deadcode::ParserError => e
  $stderr.puts "Error parsing #{file}: #{e.message}"
  next
end

# index.all_definitions.sort_by(&:name).each do |defn|
#   puts "#{defn.name} - #{defn.location}"
# end

# index.all_references.sort_by(&:name).each do |ref|
#   puts "#{ref.name} - #{ref.location}"
# end

definitions_count = index.definitions.size.to_s
references_count = index.references.size.to_s
$stderr.puts "Analyzing #{definitions_count} definitions against #{references_count} references..."

index.finalize!
dead = index.definitions.values.flatten.select(&:dead?)
dead.sort_by!(&:name)

if dead.empty?
  $stderr.puts "\nNo dead code found!"
else
  $stderr.puts "\nCandidates:"
  dead.each do |definition|
    # $stderr.puts "  #{definition.full_name} #{definition.location}"
    puts definition.full_name
  end
  $stderr.puts "\n  Found #{dead.size} dead candidates"
end
