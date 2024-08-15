# typed: strict
# frozen_string_literal: true

require "test_helper"

module Spoom
  class FixturesTest < Minitest::Test
    extend T::Sig

    fixtures_path = File.expand_path("fixtures", __dir__)
    fixture_files = Dir.glob("#{fixtures_path}/**/*.rb")

    fixture_files.each do |file|
      name = File.basename(file, ".rb")

      define_method("test_#{name}") do
        T.bind(self, FixturesTest)
        run_fixture(file)
      end
    end

    private

    sig { params(fixture_file: String).void }
    def run_fixture(fixture_file)
      snippet = Spoom::Snippet.from_file(fixture_file)

      files = []
      result = Spoom::Typecheck.run_snippet(files, snippet)
      node = T.must(result.parsed_files.map(&:last).first)

      # puts result.errors.map { |e| "#{e.location} error: #{e.message}" }.join("\n")

      replacements = []
      errors_found = Set.new

      snippet.commands.each do |command|
        case command.name
        when "node"
          target_node = Spoom::Parse::FindNodeAtLocation.find(node, command.target_location)
          raise unless target_node

          replacements << [command, target_node.class.to_s]
        when "type"
          target_node = Spoom::Parse::FindNodeAtLocation.find(node, command.target_location)
          raise unless target_node

          replacements << [command, target_node.spoom_type&.to_rbi || "<nil>"]
        when "error"
          target_errors = result.errors.select do |e|
            start_column = command.target_location.start_column
            if start_column
              e.location == command.target_location
            else
              e.location.start_line == command.target_location.start_line
            end
          end
          errors_found.merge(target_errors)

          if target_errors.empty?
            replacements << [command, "No error found"]
            next
          end

          target_errors.each do |error|
            replacements << [command, error.message]
          end
        when "typed", "frozen_string_literal"
          # no-op
        else
          raise "Unknown command: #{command.name}"
        end
      end

      unexpected_errors = result.errors - errors_found.to_a

      content = File.read(fixture_file)

      lines = snippet.render(content, replacements).lines
      unexpected_errors.sort_by(&:location).reverse.each do |error|
        start_line = T.must(error.location.start_line)
        start_column = T.must(error.location.start_column)

        if start_column < 2
          lines[start_line - 1] = "#{lines[start_line - 1]&.rstrip} # #{error.message}\n"
        else
          line = T.must(lines[start_line])
          indent = " " * (start_column - 2)

          lines.insert(
            start_line,
            "#{indent}# #{"^" * (T.must(error.location.end_column) - start_column)} error: #{error.message}\n",
          )
        end
      end

      output = lines.join
      # puts content
      # puts "----"
      # puts output

      if content != output
        puts diff(content, output)
        raise "Output does not match for #{fixture_file}"
      end

      if unexpected_errors.any?
        raise "Unexpected errors: #{unexpected_errors.map(&:message).join("\n")}"
      end
    end
  end
end
