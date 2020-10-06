# typed: true
# frozen_string_literal: true

require "pathname"

require_relative "../../git_test_helper"
require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class CoverageTest < Minitest::Test
        extend T::Sig
        extend Spoom::Cli::TestHelper
        include Spoom::Cli::TestHelper
        include Spoom::Git::TestHelper

        PROJECT = "project"

        before_all do
          install_sorbet(PROJECT)
        end

        def setup
          use_sorbet_config(PROJECT, <<~CFG)
            .
            --ignore=errors
          CFG
        end

        def test_display_metrics
          out, _ = run_cli(PROJECT, "coverage snapshot")
          assert_equal(<<~MSG, out)
            Content:
              files: 6
              modules: 2
              classes: 16 (including singleton classes)
              methods: 22

            Sigils:
              true: 6 (100%)

            Methods:
              with signature: 2 (9%)
              without signature: 20 (91%)

            Calls:
              typed: 47 (92%)
              untyped: 4 (8%)
          MSG
        end

        def test_display_metrics_do_not_show_errors
          use_sorbet_config(PROJECT, ".")
          out, _ = run_cli(PROJECT, "coverage")
          assert_equal(<<~MSG, out)
            Content:
              files: 7
              modules: 2
              classes: 18 (including singleton classes)
              methods: 25

            Sigils:
              true: 7 (100%)

            Methods:
              with signature: 3 (12%)
              without signature: 22 (88%)

            Calls:
              typed: 53 (87%)
              untyped: 8 (13%)
          MSG
        end

        def test_timeline_outside_sorbet_dir
          repo = repo("test_timeline_outside_sorbet_dir")
          out, err, status = run_cli(repo.name, "coverage timeline")
          refute(status)
          assert_equal("", out)
          assert_equal(<<~MSG, err)
            Error: not in a Sorbet project (no sorbet/config)
          MSG
          repo.destroy
        end

        def test_timeline_one_commit
          repo = repo("test_timeline_one_commit")
          repo.write_file("sorbet/config", ".")
          repo.commit
          out, err, status = run_cli(repo.name, "coverage timeline")
          assert(status)
          out&.gsub!(/commit [a-f0-9]+ - \d{4}-\d{2}-\d{2}/, "COMMIT")
          assert_equal(<<~OUT, out)
            Analyzing COMMIT (1 / 1)
              Content:
                files: 0
                modules: 0
                classes: 0 (including singleton classes)
                methods: 0

              Sigils:

              Methods:

              Calls:

          OUT
          assert_equal("", err)
          repo.destroy
        end

        def test_timeline_multiple_commits
          repo = repo_with_history("test_timeline_multiple_commits")
          out, err, status = run_cli(repo.name, "coverage timeline")
          assert(status)
          out&.gsub!(/commit [a-f0-9]+ - \d{4}-\d{2}-\d{2}/, "COMMIT")
          assert_equal(<<~OUT, out)
            Analyzing COMMIT (1 / 3)
              Content:
                files: 2
                modules: 1
                classes: 3 (including singleton classes)
                methods: 6

              Sigils:
                false: 1 (50%)
                strict: 1 (50%)

              Methods:
                with signature: 1 (17%)
                without signature: 5 (83%)

              Calls:
                typed: 6 (100%)

            Analyzing COMMIT (2 / 3)
              Content:
                files: 4
                modules: 1
                classes: 5 (including singleton classes)
                methods: 9

              Sigils:
                false: 2 (50%)
                true: 1 (25%)
                strict: 1 (25%)

              Methods:
                with signature: 1 (11%)
                without signature: 8 (89%)

              Calls:
                typed: 7 (100%)

            Analyzing COMMIT (3 / 3)
              Content:
                files: 6
                modules: 1
                classes: 5 (including singleton classes)
                methods: 10

              Sigils:
                ignore: 1 (17%)
                false: 3 (50%)
                true: 1 (17%)
                strict: 1 (17%)

              Methods:
                with signature: 1 (10%)
                without signature: 9 (90%)

              Calls:
                typed: 7 (100%)

          OUT
          assert_equal("", err)
          repo.destroy
        end

        def test_timeline_multiple_commits_between_dates
          repo = repo_with_history("test_timeline_multiple_commits_between_dates")
          out, err, status = run_cli(repo.name, "coverage timeline --from 2010-01-02 --to 2010-02-02")
          assert(status)
          out&.gsub!(/commit [a-f0-9]+ - \d{4}-\d{2}-\d{2}/, "COMMIT")
          assert_equal(<<~OUT, out)
            Analyzing COMMIT (1 / 2)
              Content:
                files: 2
                modules: 1
                classes: 3 (including singleton classes)
                methods: 6

              Sigils:
                false: 1 (50%)
                strict: 1 (50%)

              Methods:
                with signature: 1 (17%)
                without signature: 5 (83%)

              Calls:
                typed: 6 (100%)

            Analyzing COMMIT (2 / 2)
              Content:
                files: 4
                modules: 1
                classes: 5 (including singleton classes)
                methods: 9

              Sigils:
                false: 2 (50%)
                true: 1 (25%)
                strict: 1 (25%)

              Methods:
                with signature: 1 (11%)
                without signature: 8 (89%)

              Calls:
                typed: 7 (100%)

          OUT
          assert_equal("", err)
          repo.destroy
        end

        def test_timeline_multiple_commits_and_save_json
          repo = repo_with_history("test_timeline_multiple_commits_and_save_json")
          _, err, status = run_cli(repo.name, "coverage timeline --save-dir spoom_data")
          assert(status)
          assert_equal("", err)
          assert(3, Dir.glob("#{repo.path}/spoom_data/*.json").size)
          repo.destroy
        end

        private

        sig { params(name: String).returns(Spoom::Git::TestHelper::TestRepo) }
        def repo_with_history(name)
          repo = repo(name)
          repo.write_file("sorbet/config", ".")
          repo.write_file("a.rb", <<~RB)
            # typed: false
            class Foo
              def foo
                Bar.bar
              end
            end
          RB
          repo.write_file("b.rb", <<~RB)
            # typed: strict
            module Bar
              extend T::Sig

              sig { void}
              def self.bar; end
            end
          RB
          repo.commit(date: Time.parse("2010-01-02 03:04:05"))
          repo.write_file("c.rb", <<~RB)
            # typed: false
            class Baz; end
          RB
          repo.write_file("d.rb", <<~RB)
            # typed: true
            Baz.new
          RB
          repo.commit(date: Time.parse("2010-02-02 03:04:05"))
          repo.write_file("e.rb", "# typed: ignore")
          repo.write_file("f.rb", "# typed: __INTERNAL_STDLIB")
          repo.commit(date: Time.parse("2010-03-02 03:04:05"))
          repo
        end
      end
    end
  end
end
