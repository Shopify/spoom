# typed: true
# frozen_string_literal: true

require_relative "../tests"

module Spoom
  module Cli
    class Tests < Thor
      include Helper

      DEFAULT_OUTPUT_FILE = "coverage.json"

      default_task :show

      desc "show", "Show information about tests"
      def show
        guess_framework(context)
      end

      desc "list", "List tests"
      def list
        framework, test_files = guess_framework(context)

        test_files.each do |test_file|
          say(" * #{test_file.path}")
        end

        # TODO: match tests from args
      end

      # TODO: list test cases/suites + tests

      desc "test", "Run tests"
      def test(*paths)
        context = self.context
        framework, test_files = guess_framework(context)

        if paths.any?
          test_files = paths.flat_map { |path| context.glob(path) }.map { |path| Tests::File.new(path) }
        end

        say("\nRunning `#{test_files.size}` test files\n\n")

        framework.install!(context)
        framework.run_tests(context, test_files)
      end

      desc "coverage", "Run tests coverage"
      option :output, type: :string, default: DEFAULT_OUTPUT_FILE, desc: "Output file"
      def coverage(*paths)
        context = self.context
        framework, test_files = guess_framework(context)

        if paths.any?
          test_files = paths.flat_map { |path| context.glob(path) }.map { |path| Spoom::Tests::File.new(path) }
        end

        framework.install!(context)

        coverage = framework.run_coverage(context, test_files)
        compressed = []
        coverage.results.each do |(test_case, test_coverage)|
          compressed << {
            test_case: test_case,
            coverage: test_coverage.map do |file, lines|
              [
                file,
                lines.map.with_index do |value, index|
                  next if value.nil? || value == 0

                  index + 1
                end.compact,
              ]
            end.select { |(_file, lines)| lines.any? }.compact.to_h,
          }
        end

        output_file = Pathname.new(options[:output])
        FileUtils.mkdir_p(output_file.dirname)
        File.write(output_file, compressed.to_json)
        say("\nCoverage data saved to `#{output_file}`")
        # TODO: tests
      end

      desc "map", "Map tests to source files"
      option :output, type: :string, default: DEFAULT_OUTPUT_FILE, desc: "Output file"
      def map(test_full_name)
        hash = JSON.parse(File.read(options[:output]))

        hash.each do |entry|
          test_case = entry["test_case"]
          next unless "#{test_case["klass"]}##{test_case["name"]}" == test_full_name

          puts "#{test_case[:file]}:#{test_case[:line]}"

          coverage = entry["coverage"]
          coverage.each do |file, lines|
            puts "  #{file}"
            lines.each_with_index do |line, index|
              puts "    #{index}: #{line}"
            end
          end
        end
      end

      no_commands do
        def guess_framework(context)
          framework = begin
            Spoom::Tests.guess_framework(context)
          rescue Spoom::Tests::CantGuessTestFramework => e
            say_error(e.message)
            exit(1)
          end

          test_files = framework.test_files(context)
          say("Matched framework `#{framework.framework_name}`, found `#{test_files.size}` test files")

          [framework, test_files]
        end
      end
    end
  end
end

# spoom, rbi
# tapioca
# code-db
# core?

# TODO: tests
#   TODO: run
#   TODO: coverage
