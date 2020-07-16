# typed: false
# frozen_string_literal: true

require 'pathname'

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class BumpTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        TEMPORARY_DIRECTORY = "temp"

        def teardown
          FileUtils.remove_dir(TEMPORARY_DIRECTORY, true)
        end

        def test_bump_files_one_error_one_no_error_acceptance
          content1  = <<~STR
            # typed: false
            class A; end
          STR

          content2  = <<~STR
            # typed: false
            T.reveal_type(1.to_s)
          STR

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)

          File.write("#{TEMPORARY_DIRECTORY}/file1.rb", content1)
          File.write("#{TEMPORARY_DIRECTORY}/file2.rb", content2)

          Bump.new.bump(TEMPORARY_DIRECTORY, "rb")

          strictness1 = Bump.file_strictness("#{TEMPORARY_DIRECTORY}/file1.rb")
          strictness2 = Bump.file_strictness("#{TEMPORARY_DIRECTORY}/file2.rb")

          assert_equal("true", strictness1)
          assert_equal("false", strictness2)
        end

        def test_files_with_sigil_strictness_nested_directory
          content_false = <<~STR
            # typed: false
          STR

          content_true = <<~STR
            # typed: true
          STR

          temporary_directory = "temp2"

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)
          FileUtils.mkdir_p("#{TEMPORARY_DIRECTORY}/nested")

          File.write("#{TEMPORARY_DIRECTORY}/false.tmp", content_false)
          File.write("#{TEMPORARY_DIRECTORY}/true.tmp", content_true)

          File.write("#{TEMPORARY_DIRECTORY}/nested/false.tmp", content_false)
          File.write("#{TEMPORARY_DIRECTORY}/nested/true.tmp", content_true)

          files = Bump.files_with_sigil_strictness("#{TEMPORARY_DIRECTORY}", "false", "tmp").sort
          expected_files = ["#{File.expand_path(TEMPORARY_DIRECTORY)}/false.tmp",
            "#{File.expand_path(TEMPORARY_DIRECTORY)}/nested/false.tmp"]

          assert_equal(expected_files, files)
        end

        def test_file_names_from_errors
          errors = []
          errors << Spoom::Sorbet::Errors::Error.new("file1", 1, "", 1)
          errors << Spoom::Sorbet::Errors::Error.new("file2", 2, "", 2)
          errors << Spoom::Sorbet::Errors::Error.new("file3", 3, "", 3)

          files = Bump.file_names_from_error(errors)

          assert_equal(["file1", "file2", "file3"], files)
        end

        def test_file_strictness_with_valid_sigil
          content  = <<~STR
            # typed: true
            class A; end
          STR

          File.write("file.tmp", content)

          strictness = Bump.file_strictness("file.tmp")

          File.delete("file.tmp")

          assert_equal("true", strictness)
        end

        def test_file_strictness_with_invalid_sigil
          content  = <<~STR
            # typed: asdf
            class A; end
          STR

          File.write("file.tmp", content)

          strictness = Bump.file_strictness("file.tmp")

          File.delete("file.tmp")

          assert_equal("asdf", strictness)
        end

        def test_update_sigil_in_file_false_to_true
          content = <<~STR
            # typed: false
            class A; end
          STR

          File.write("file.tmp", content)

          Bump.change_sigil_in_file("file.tmp", "true")

          new_strictness = Bump.file_strictness("file.tmp")

          File.delete("file.tmp")

          assert_equal("true", new_strictness)
        end

        def test_update_sigil_in_files_false_to_true
          content1 = <<~STR
            # typed: false
            class A; end
          STR

          content2 = <<~STR
            # typed: ignore
            class B; end
          STR

          File.write("file1.tmp", content1)
          File.write("file2.tmp", content2)

          Bump.change_sigil_in_files(["file1.tmp", "file2.tmp"], "true")

          new_strictness1 = Bump.file_strictness("file1.tmp")
          new_strictness2 = Bump.file_strictness("file2.tmp")

          File.delete("file1.tmp")
          File.delete("file2.tmp")

          assert_equal("true", new_strictness1)
          assert_equal("true", new_strictness2)
        end
      end
    end
  end
end
