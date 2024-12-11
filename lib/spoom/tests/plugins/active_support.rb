# typed: strict
# frozen_string_literal: true

module Spoom
  module Tests
    module Plugins
      class ActiveSupport < Plugin
        TESTS_ROOT = "test"
        TEST_GLOB = T.let("#{TESTS_ROOT}/**/*_test.rb", String)
        APPLICATION_FILE = T.let("config/application.rb", String)

        class << self
          sig { override.params(context: Context).returns(T::Boolean) }
          def match_context?(context)
            context.file?(APPLICATION_FILE) && context.glob(TEST_GLOB).any?
          end

          sig { override.params(context: Context).returns(T::Array[Tests::File]) }
          def test_files(context)
            context.glob(TEST_GLOB).map { |path| Tests::File.new(path) }
          end

          sig { override.params(context: Context).void }
          def install!(context)
            require "minitest"

            # Disable autorun
            ::Minitest.singleton_class.define_method(:autorun, -> {})

            old_run_one_method = ::Minitest::Runnable.method(:run_one_method)
            ::Minitest::Runnable.singleton_class.define_method(:run_one_method, ->(*args) do
              raise unless $COVERAGE_OUTPUT

              old_run_one_method.call(*args)

              coverage = ::Coverage.peek_result.select { |file, _| file.start_with?(context.absolute_path) }
              test_class = args[0]
              test_method = args[1]
              test_file, test_line = begin
                test_class.new(test_method).method(test_method).source_location
              rescue
                ["unknown", -1]
              end
              test_case = TestCase.new(klass: test_class.name, name: test_method, file: test_file, line: test_line)
              $COVERAGE_OUTPUT << [test_case, coverage]
            end)
          end

          sig { override.params(context: Context, test_files: T::Array[Tests::File]).returns(T::Boolean) }
          def run_tests(context, test_files)
            $LOAD_PATH.unshift(context.absolute_path_to(TESTS_ROOT))
            test_files.each do |test_file|
              load(context.absolute_path_to(test_file.path))
            end
            ::Minitest.run(test_files.map(&:path))
          end

          sig { override.params(context: Context, test_files: T::Array[Tests::File]).returns(Coverage) }
          def run_coverage(context, test_files)
            $LOAD_PATH.unshift(context.absolute_path_to(TESTS_ROOT))
            test_files.each do |test_file|
              load(context.absolute_path_to(test_file.path))
            end
            $COVERAGE_OUTPUT = Spoom::Tests::Coverage.new
            ::Minitest.run(test_files.map(&:path))
            results = $COVERAGE_OUTPUT
            $COVERAGE_OUTPUT = nil

            results
          end
        end
      end
    end
  end
end
