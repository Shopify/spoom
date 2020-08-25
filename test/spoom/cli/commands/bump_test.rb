# typed: true
# frozen_string_literal: true

require 'pathname'

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class BumpTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        PROJECT = "project-bump"
        TEMPORARY_DIRECTORY = "#{TEST_PROJECTS_PATH}/#{PROJECT}/test-bump"

        before_all do
          install_sorbet(PROJECT)
        end

        def setup
          use_sorbet_config(PROJECT, <<~CFG)
            .
          CFG
        end

        def teardown
          FileUtils.remove_dir(TEMPORARY_DIRECTORY, true)
        end

        def test_bump_files_one_error_no_bump_one_no_error_bump
          content1 = <<~STR
            # typed: false
            class A; end
          STR

          content2 = <<~STR
            # typed: false
            T.reveal_type(1)
          STR

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)

          File.write("#{TEMPORARY_DIRECTORY}/file1.rb", content1)
          File.write("#{TEMPORARY_DIRECTORY}/file2.rb", content2)

          run_cli(PROJECT, "bump")

          strictness1 = Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file1.rb")
          strictness2 = Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file2.rb")

          assert_equal("true", strictness1)
          assert_equal("false", strictness2)
        end

        def test_bump_doesnt_change_sigils_outside_directory
          content = <<~STR
            # typed: true
            T.reveal_type(1)
          STR

          File.write("file.rb", content)

          run_cli(PROJECT, "bump")

          strictness = Sorbet::Sigils.file_strictness("file.rb")

          assert_equal("true", strictness)

          File.delete("file.rb")
        end

        def test_bump_nondefault_from_to_complete
          from = "true"
          to = "strict"

          content = <<~STR
            # typed: #{from}
            class A; end
          STR

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)

          File.write("#{TEMPORARY_DIRECTORY}/file.rb", content)

          run_cli(PROJECT, "bump --from #{from} --to #{to}")

          strictness = Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file.rb")

          assert_equal("strict", strictness)
        end

        def test_bump_nondefault_from_to_revert
          from = "ignore"
          to = "strong"

          content = <<~STR
            # typed: #{from}
            T.reveal_type(1)
          STR

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)

          File.write("#{TEMPORARY_DIRECTORY}/file.rb", content)

          run_cli(PROJECT, "bump --from #{from} --to #{to}")

          strictness = Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file.rb")

          assert_equal("ignore", strictness)
        end

        def test_force_bump_without_typecheck
          content = <<~STR
            # typed: false
            T.reveal_type(1)
          STR

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)

          File.write("#{TEMPORARY_DIRECTORY}/file.rb", content)

          run_cli(PROJECT, "bump --force")

          strictness = Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file.rb")

          assert_equal("true", strictness)
        end
      end
    end
  end
end
