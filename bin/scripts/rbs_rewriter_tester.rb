# typed: ignore
# devx opencode -s ses_14213e0f5ffeZhvMIpRnsDfCly

$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
require "spoom"
require "ruby-progressbar"
require "optparse"
require "set"

# Only keep a handful of failing-file examples per category so memory stays
# bounded when testing over very large file sets.
SAMPLE_LIMIT = 10

# Renders a Markdown table. `headers` is the header row (first cell is the
# row-label column). `rows` is an array of cell arrays, each the same length as
# `headers`. Every column is right-aligned.
def render_table(headers, rows)
  widths = headers.each_index.map do |i|
    ([headers[i]] + rows.map { |row| row[i] }).map(&:length).max
  end

  render_row = ->(cells) do
    "| " + cells.each_with_index.map { |cell, i| cell.rjust(widths[i]) }.join(" | ") + " |"
  end

  separator = "|" + widths.each_with_index.map do |width, i|
    dashes = "-" * (width + 2)
    i.zero? ? dashes : "#{dashes[0..-2]}:" # right-align marker for value columns
  end.join("|") + "|"

  [render_row.call(headers), separator, *rows.map { |row| render_row.call(row) }].join("\n")
end

# Renders syntax errors the way `ruby -c` does: a line-numbered window around
# each error with a caret and inline message (only the lines near the error, not
# the whole file). This reuses CRuby's own Prism formatter, which surfaces via
# the SyntaxError raised when compiling. Falls back to a terse line:col listing
# if compiling doesn't raise (e.g. Prism.parse and the compiler disagree).
def format_parse_errors(source, file_path, indent: "    ")
  message =
    begin
      RubyVM::InstructionSequence.compile(source, file_path)
      nil # Compiled cleanly, so fall back below.
    rescue SyntaxError => e
      e.message
    end

  lines = if message
    body = message.lines
    body = body.drop(1) if body.first&.include?("syntax error") # drop the redundant "<file>:<line>:" header
    body
  else
    Prism.parse(source).errors.map do |error|
      location = error.location
      "#{location.start_line}:#{location.start_column}: #{error.message}\n"
    end
  end

  lines.map { |line| "#{indent}#{line}" }.join
end

extensions = Set["rb"] # Always search `.rb` files by default.

# [label, translator class] pairs. Defaults to running both (--rewriter both).
human = ["Human readable", Spoom::Sorbet::Translate::RBSCommentsToSorbetSigs::HumanReadableTranslator]
line_matching = ["Line-matching", Spoom::Sorbet::Translate::RBSCommentsToSorbetSigs::LineMatchingTranslator]
selected_rewriters = [human, line_matching]

just_print_rewritten_output = false
OptionParser.new do |opts|
  opts.banner = "Usage: rbs_rewriter_tester.rb [options] PATH"

  opts.on("--print-rewrite") do
    # This is for debugging: print the rewritten version of each file to STDOUT.
    just_print_rewritten_output = true
  end

  opts.on("--include-ext EXT", "When PATH is a directory, also process files with this extension (default: rb only). Repeatable.") do |ext|
    extensions << ext.delete_prefix(".")
  end

  opts.on("--rewriter NAME", ["human", "line-matching", "both"],
    "Which rewriter(s) to run: human, line-matching, or both (default: both)") do |name|
    selected_rewriters = case name
    when "human" then [human]
    when "line-matching" then [line_matching]
    when "both" then [human, line_matching]
    end
  end
end.parse!

if just_print_rewritten_output
  selected_rewriters = [line_matching] # line-matching is closer to the final output format, so better for debugging.
  rewritten = Spoom::Sorbet::Translate::RBSCommentsToSorbetSigs::LineMatchingTranslator.new(ARGF.read, file: ARGF.path).rewrite
  puts rewritten
  exit
end

path = File.expand_path(ARGV[0] || ".")
files = if File.directory?(path)
  Dir["#{path}/**/*.{#{extensions.join(",")}}"]
else
  [path]
end

# files = [
#   "/Users/alex/world/trees/root/src/areas/core/shopify/bin/ci/lib/execution_strategy.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/components/access_and_auth/customer_authentication_provider/test/integration/access_and_auth/customer_authentication_provider/revocation_controller_test.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/components/access_and_auth/customer_authentication_provider/test/models/access_and_auth/customer_authentication_provider/provider_adapters/vendor_adapter_test.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/components/developer_dashboard/apps/test/views/developer_dashboard/apps/show_test.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/components/developer_dashboard/essentials/test/views/layouts/developer_dashboard/app_frame/app_frame_test.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/components/merchandising/test/models/graph_api/admin/variants_page_limit_test.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/components/merchandising/test/support/helpers/merchandising/dynamic_complexity_cost_test_helper.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/components/platform/essentials/lib/development_support/globaldb_primary_key_collector.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/components/platform/essentials/lib/development_support/migration_sql_compiler.rb",
#   "/Users/alex/world/trees/root/src/areas/core/shopify/gems/sqlite_test_compat/lib/active_record/sqlite3_semian_stub.rb",
# ]

progress = ProgressBar.create(
  title: "Rewriting",
  total: files.size,
  format: "%t |%B| %c/%C (%p%%) %e",
  progress_mark: "█",
  remainder_mark: "·",
)

# Shared (rewriter-independent) tallies.
invalid_ruby_count = 0
invalid_ruby_samples = []
not_rbs_count = 0

# Per-rewriter result data, keyed by label.
stats = selected_rewriters.to_h do |label, _|
  [label, { rewritten: 0, rewrite_failures: 0, parse_failures: 0, validation_failures: 0, elapsed: 0.0 }]
end

# Capped examples of failing files for the detail sections: samples[label][category] => [[path, detail], ...]
samples = Hash.new { |h, label| h[label] = Hash.new { |hh, category| hh[category] = [] } }
record_sample = ->(label, category, entry) do
  bucket = samples[label][category]
  bucket << entry if bucket.size < SAMPLE_LIMIT
end

files.each do |file_path|
  original = File.read(file_path)

  # Confirm the original file parses before attempting to rewrite it.
  if Prism.parse(original).failure?
    invalid_ruby_count += 1
    invalid_ruby_samples << [file_path, original] if invalid_ruby_samples.size < SAMPLE_LIMIT
    next
  end

  # Whether the file contains RBS syntax is independent of the rewriter, so check once.
  unless Spoom::Sorbet::Translate::RBSCommentsToSorbetSigs.contains_rbs_syntax?(original)
    not_rbs_count += 1
    next
  end

  # Run every selected rewriter over the same file so the read/parse cost is paid once.
  selected_rewriters.each do |label, translator_class|
    counts = stats[label]

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    begin
      rewritten = translator_class.new(original, file: file_path).rewrite
    rescue => e
      counts[:rewrite_failures] += 1
      record_sample.call(label, :rewrite_failures, [file_path, e])
      next
    ensure
      counts[:elapsed] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    end
    counts[:rewritten] += 1

    if Prism.parse(rewritten).failure?
      counts[:parse_failures] += 1
      record_sample.call(label, :parse_failures, [file_path, rewritten])
    end

    unless (validation = Spoom::Sorbet::Translate::Validator.validate(original, rewritten)).valid?
      counts[:validation_failures] += 1
      record_sample.call(label, :validation_failures, [file_path, validation])
    end
  end
ensure
  progress.increment
end

progress.finish

unless invalid_ruby_samples.empty?
  puts
  puts "Invalid Ruby:"
  invalid_ruby_samples.each do |file_path, source|
    puts "  #{file_path}"
    puts format_parse_errors(source, file_path)
  end
end

selected_rewriters.each do |label, translator_class|
  label_samples = samples[label]

  unless label_samples[:rewrite_failures].empty?
    puts
    puts "#{label} - rewrite errors:"
    label_samples[:rewrite_failures].each do |file_path, error|
      puts "  #{file_path}: #{error.class}: #{error.message}"
    end
  end

  unless label_samples[:parse_failures].empty?
    puts
    puts "#{label} - parse failures:"
    label_samples[:parse_failures].each do |file_path, source|
      puts "  #{file_path}"
      puts format_parse_errors(source, file_path)
    end
  end

  if Spoom::Sorbet::Translate::RBSCommentsToSorbetSigs::LineMatchingTranslator == translator_class
    unless label_samples[:validation_failures].empty?
      puts
      puts "#{label} - validation failures:"
      label_samples[:validation_failures].each do |file_path, result|
        puts "  #{file_path}"
        result.errors.each { |error| puts "    #{error}" }
      end
    end
  end
end


puts
puts "Summary"
puts "-------"
printf("%-16s%8d\n", "Files processed:", files.size)
printf("%-16s%8d\n", "Invalid Ruby:", invalid_ruby_count)
printf("%-16s%8d\n", "Not RBS:", not_rbs_count)

puts
puts "Results:"
puts

headers = [""] + selected_rewriters.map { |label, _| label }
headers << "New errors" if selected_rewriters.size > 1

rows = {
  "Rewritten:" => :rewritten,
  "Rewrite failures:" => :rewrite_failures,
  "Parse failures:" => :parse_failures,
  "Validation failures:" => :validation_failures,
  "Elapsed:" => :elapsed,
}.map do |row_label, key|
  format_value = key == :elapsed ? ->(v) { format("%.2fs", v) } : ->(v) { v.to_s }
  values = selected_rewriters.map { |label, _| stats[label][key] }
  cells = [row_label, *values.map(&format_value)]
  cells << format_value.call(values.last - values.first) if selected_rewriters.size > 1 # line-matching - human
  cells
end

puts render_table(headers, rows)
