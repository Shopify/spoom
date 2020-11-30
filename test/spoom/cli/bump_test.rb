# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Cli
    class BumpTest < Minitest::Test
      include Spoom::TestHelper

      def setup
        @project = spoom_project("test_bump")
        @project.sorbet_config(".")
      end

      def teardown
        @project.destroy
      end

      def test_bump_outside_sorbet_dir
        @project.remove("sorbet/config")
        out, err, status = @project.bundle_exec("spoom bump --no-color")
        assert_empty(out)
        assert_equal("Error: not in a Sorbet project (sorbet/config not found)", err.lines.first.chomp)
        refute(status)
      end

      def test_bump_files_one_error_no_bump_one_no_error_bump
        @project.write("file1.rb", <<~RB)
          # typed: false
          class A; end
        RB
        @project.write("file2.rb", <<~RB)
          # typed: false
          T.reveal_type(1)
        RB

        @project.bundle_exec("spoom bump")

        assert_equal("true", Sorbet::Sigils.file_strictness("#{@project.path}/file1.rb"))
        assert_equal("false", Sorbet::Sigils.file_strictness("#{@project.path}/file2.rb"))
      end

      def test_bump_doesnt_change_sigils_outside_directory
        @project.write("lib/a/file.rb", "# typed: false")
        @project.write("lib/b/file.rb", "# typed: false")
        @project.write("lib/c/file.rb", "# typed: true\n\nfoo.bar")
        @project.bundle_exec("spoom bump lib/b")

        assert_equal("false", Sorbet::Sigils.file_strictness("#{@project.path}/lib/a/file.rb"))
        assert_equal("true", Sorbet::Sigils.file_strictness("#{@project.path}/lib/b/file.rb"))
        assert_equal("true", Sorbet::Sigils.file_strictness("#{@project.path}/lib/c/file.rb"))

        @project.destroy
      end

      def test_bump_nondefault_from_to_complete
        @project.write("file1.rb", <<~RB)
          # typed: false
          class A; end
        RB
        @project.write("file2.rb", <<~RB)
          # typed: true
          class B; end
        RB

        @project.bundle_exec("spoom bump --from true --to strict")

        assert_equal("false", Sorbet::Sigils.file_strictness("#{@project.path}/file1.rb"))
        assert_equal("strict", Sorbet::Sigils.file_strictness("#{@project.path}/file2.rb"))
      end

      def test_bump_nondefault_from_to_revert
        @project.write("file1.rb", <<~RB)
          # typed: ignore
          class A; end
        RB
        @project.write("file2.rb", <<~RB)
          # typed: ignore
          T.reveal_type(1)
        RB

        @project.bundle_exec("spoom bump --from ignore --to strong")

        assert_equal("strong", Sorbet::Sigils.file_strictness("#{@project.path}/file1.rb"))
        assert_equal("ignore", Sorbet::Sigils.file_strictness("#{@project.path}/file2.rb"))
      end

      def test_force_bump_without_typecheck
        @project.write("file1.rb", <<~RB)
          # typed: ignore
          class A; end
        RB
        @project.write("file2.rb", <<~RB)
          # typed: ignore
          T.reveal_type(1)
        RB

        @project.bundle_exec("spoom bump --force --from ignore --to strong")

        assert_equal("strong", Sorbet::Sigils.file_strictness("#{@project.path}/file1.rb"))
        assert_equal("strong", Sorbet::Sigils.file_strictness("#{@project.path}/file2.rb"))
      end

      def test_bump_with_multiline_error
        @project.write("file.rb", <<~RB)
          # typed: true
          require "test_helper"

          class Test
            def self.foo(*arg); end
            def self.something; end
            def self.something_else; end

            foo "foo" do
              q = something do
                q = something_else.new
              end
            end
          end
        RB

        _, _, status = @project.bundle_exec("spoom bump --from true --to strict")
        assert(status)

        assert_equal("true", Sorbet::Sigils.file_strictness("#{@project.path}/file.rb"))
      end
    end
  end
end
