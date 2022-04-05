# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class SigilsTest < Minitest::Test
      include Spoom::TestHelper

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
        project = spoom_project
        project.write("false.rb", "# typed: false")
        project.write("true.rb", "# typed: true")
        project.write("nested/false.rb", "# typed: false")
        project.write("nested/true.rb", "# typed: true")

        files = Sigils.files_with_sigil_strictness(project.path, "false").sort

        expected_files = [
          "#{project.path}/false.rb",
          "#{project.path}/nested/false.rb",
        ]
        assert_equal(expected_files, files)

        project.destroy
      end

      def test_files_with_sigil_strictness_with_iso_content
        project = spoom_project

        string_utf = <<~RB
          # typed: true

          puts "À coûté 10€"
        RB

        string_iso = string_utf.encode("ISO-8859-15")
        project.write("file1.rb", string_iso)
        project.write("file2.rb", string_iso)
        expected_files = ["#{project.path}/file1.rb", "#{project.path}/file2.rb"]

        files = Sigils.files_with_sigil_strictness(project.path, "true").sort
        assert_equal(expected_files, files)

        project.destroy
      end

      def test_file_strictness_returns_nil_if_file_not_found
        strictness = Sigils.file_strictness("/file/not/found.rb")
        assert_nil(strictness)
      end

      def test_file_strictness_returns_nil_if_file_is_dir
        strictness = Sigils.file_strictness("/")
        assert_nil(strictness)
      end

      def test_file_strictness_with_valid_sigil
        project = spoom_project
        project.write("file.rb", "# typed: true")
        strictness = Sigils.file_strictness("#{project.path}/file.rb")
        assert_equal("true", strictness)
        project.destroy
      end

      def test_file_strictness_with_invalid_sigil
        project = spoom_project
        project.write("file.rb", "# typed: asdf")
        strictness = Sigils.file_strictness("#{project.path}/file.rb")
        assert_equal("asdf", strictness)
        project.destroy
      end

      def test_file_strictness_with_iso_content
        project = spoom_project

        string = <<~RB
          # typed: true

          puts "À coûté 10€"
        RB

        project.write("file.rb", string.encode("ISO-8859-15"))
        strictness = Sigils.file_strictness("#{project.path}/file.rb")
        assert_equal("true", strictness)
        project.destroy
      end

      def test_change_sigil_in_file_false_to_true
        project = spoom_project
        project.write("file.rb", "# typed: false")
        updated = Sigils.change_sigil_in_file("#{project.path}/file.rb", "true")
        assert(updated)
        strictness = Sigils.file_strictness("#{project.path}/file.rb")
        assert_equal("true", strictness)
        project.destroy
      end

      def test_change_sigil_in_file_with_iso_content
        project = spoom_project

        string = <<~RB
          # typed: true

          puts "À coûté 10€"
        RB

        project.write("file.rb", string.encode("ISO-8859-15"))
        Sigils.change_sigil_in_file("#{project.path}/file.rb", "strict")
        assert_equal("strict", Sigils.file_strictness("#{project.path}/file.rb"))
        project.destroy
      end

      def test_change_sigil_in_file_with_default_internal_encoding
        project = spoom_project

        string = <<~RB
          # typed: true

          puts "À coûté 10€"
        RB

        old_encoding = Encoding.default_internal
        project.write("file.rb", string.encode("UTF-8"))

        begin
          Encoding.default_internal = Encoding::UTF_8

          Sigils.change_sigil_in_file("#{project.path}/file.rb", "strict")
          assert_equal("strict", Sigils.file_strictness("#{project.path}/file.rb"))
        ensure
          Encoding.default_internal = old_encoding
          project.destroy
        end
      end

      def test_change_sigil_in_files_false_to_true
        project = spoom_project
        project.write("file1.rb", "# typed: false")
        project.write("file2.rb", "# typed: ignore")
        files = ["#{project.path}/file1.rb", "#{project.path}/file2.rb"]

        changed_files = Sigils.change_sigil_in_files(files, "true")
        assert_equal(files, changed_files)
        assert_equal("true", Sigils.file_strictness("#{project.path}/file1.rb"))
        assert_equal("true", Sigils.file_strictness("#{project.path}/file2.rb"))

        project.destroy
      end

      def test_change_sigil_in_files_with_iso_content
        project = spoom_project

        string_utf = <<~RB
          # typed: true

          puts "À coûté 10€"
        RB

        string_iso = string_utf.encode("ISO-8859-15")
        project.write("file1.rb", string_iso)
        project.write("file2.rb", string_iso)
        files = ["#{project.path}/file1.rb", "#{project.path}/file2.rb"]

        changed_files = Sigils.change_sigil_in_files(files, "true")
        assert_equal(files, changed_files)
        assert_equal("true", Sigils.file_strictness("#{project.path}/file1.rb"))
        assert_equal("true", Sigils.file_strictness("#{project.path}/file2.rb"))
        project.destroy
      end
    end
  end
end
