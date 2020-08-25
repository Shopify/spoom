# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class SigilsTest < Minitest::Test
      TEMPORARY_DIRECTORY = "test-sigils"

      def teardown
        FileUtils.remove_dir(TEMPORARY_DIRECTORY, true)
      end

      def test_sigil_returns_the_sigil_from_a_strictness_string
        sigil = Sigils.sigil_string("false")
        assert_equal("# typed: false", sigil)
      end

      def test_sigil_empty_returns_sigil_without_strictness
        sigil = Sigils.sigil_string("")
        assert_equal("# typed: ", sigil)
      end

      def test_valid_strictness_returns_true
        ["ignore", "false", "true", "strict", "strong", "   strong   "].each do |strictness|
          assert(Sigils.valid_strictness?(strictness))
        end
      end

      def test_valid_strictness_false
        ["", "FALSE", "foo"].each do |strictness|
          refute(Sigils.valid_strictness?(strictness))
        end
      end

      def test_strictness_return_expected
        ["ignore", "false", "true", "strict", "strong", "   strong   ", "foo", ""].each do |strictness|
          content = <<~STR
            # typed: #{strictness}
            class A; end
          STR

          strictness_found = Sigils.strictness_in_content(content)

          assert_equal(strictness.strip, strictness_found)
        end
      end

      def test_strictness_no_sigil_returns_nil
        content = <<~STR
          class A; end
        STR

        strictness = Sigils.strictness_in_content(content)
        assert_nil(strictness)
      end

      def test_strictness_first_valid_return
        content = <<~STR
          # typed: true
          # typed: strict
          class A; end
        STR

        strictness = Sigils.strictness_in_content(content)
        assert_equal("true", strictness)
      end

      def test_strictness_first_invalid_return
        content = <<~STR
          # typed: no
          # typed: strict
          class A; end
        STR

        strictness = Sigils.strictness_in_content(content)
        assert_equal("no", strictness)
      end

      def test_update_sigil_to_use_valid_strictness
        content = <<~STR
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "false")

        strictness = Sigils.strictness_in_content(new_content)

        assert_equal("false", strictness)
      end

      def test_update_sigil_to_use_invalid_strictness
        content = <<~STR
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "asdf")

        strictness = Sigils.strictness_in_content(new_content)

        assert_equal("asdf", strictness)
      end

      def test_update_sigil_first_of_multiple
        content = <<~STR
          # typed: strong
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "true")

        assert(/^# typed: ignore$/.match?(new_content))

        strictness = Sigils.strictness_in_content(new_content)

        assert_equal("true", strictness)
      end

      def test_files_with_sigil_strictness_nested_directory
        content_false = <<~STR
          # typed: false
        STR

        content_true = <<~STR
          # typed: true
        STR

        FileUtils.mkdir_p(TEMPORARY_DIRECTORY)
        FileUtils.mkdir_p("#{TEMPORARY_DIRECTORY}/nested")

        File.write("#{TEMPORARY_DIRECTORY}/false.tmp", content_false)
        File.write("#{TEMPORARY_DIRECTORY}/true.tmp", content_true)

        File.write("#{TEMPORARY_DIRECTORY}/nested/false.tmp", content_false)
        File.write("#{TEMPORARY_DIRECTORY}/nested/true.tmp", content_true)

        files = Sigils.files_with_sigil_strictness(TEMPORARY_DIRECTORY, "false", ".tmp").sort

        expected_files = [
          "#{File.expand_path(TEMPORARY_DIRECTORY)}/false.tmp",
          "#{File.expand_path(TEMPORARY_DIRECTORY)}/nested/false.tmp",
        ]

        assert_equal(expected_files, files)
      end

      def test_file_strictness_with_valid_sigil
        content = <<~STR
          # typed: true
          class A; end
        STR

        File.write("file.tmp", content)

        strictness = Sigils.file_strictness("file.tmp")

        File.delete("file.tmp")

        assert_equal("true", strictness)
      end

      def test_file_strictness_with_invalid_sigil
        content = <<~STR
          # typed: asdf
          class A; end
        STR

        File.write("file.tmp", content)

        strictness = Sigils.file_strictness("file.tmp")

        File.delete("file.tmp")

        assert_equal("asdf", strictness)
      end

      def test_change_sigil_in_file_false_to_true
        content = <<~STR
          # typed: false
          class A; end
        STR

        File.write("file.tmp", content)

        updated = Sigils.change_sigil_in_file("file.tmp", "true")

        new_strictness = Sigils.file_strictness("file.tmp")

        File.delete("file.tmp")

        assert_equal("true", new_strictness)
        assert(updated)
      end

      def test_change_sigil_in_files_false_to_true
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

        changed_files = Sigils.change_sigil_in_files(["file1.tmp", "file2.tmp"], "true")

        new_strictness1 = Sigils.file_strictness("file1.tmp")
        new_strictness2 = Sigils.file_strictness("file2.tmp")

        File.delete("file1.tmp")
        File.delete("file2.tmp")

        assert_equal(["file1.tmp", "file2.tmp"], changed_files)
        assert_equal("true", new_strictness1)
        assert_equal("true", new_strictness2)
      end
    end
  end
end
