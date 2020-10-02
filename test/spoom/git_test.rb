# typed: true
# frozen_string_literal: true

require "test_helper"
require_relative "git_test_helper"

module Spoom
  module Git
    class GitTest < Minitest::Test
      include Spoom::Git::TestHelper

      def test_last_commit_if_no_commit
        repo = repo("test_is_git_dir_true_if_no_commit")
        assert(Spoom::Git.last_commit(path: repo.path).nil?)
        repo.destroy
      end

      def test_last_commit
        repo = repo("test_last_commit")
        repo.write_file("file")
        repo.commit
        assert(Spoom::Git.last_commit(path: repo.path))
        repo.destroy
      end

      def test_clean_workdir_on_clean_repo
        repo = repo("test_clean_workdir_on_clean_repo")
        repo.write_file("file")
        repo.commit
        assert(Spoom::Git.workdir_clean?(path: repo.path))
        repo.destroy
      end

      def test_clean_workdir_on_dirty_repo
        repo = repo("test_clean_workdir_on_dirty_repo")
        repo.write_file("file", "content")
        repo.commit
        repo.write_file("file", "content2")
        refute(Spoom::Git.workdir_clean?(path: repo.path))
        repo.destroy
      end

      def test_commit_timestamp
        date = Time.parse("1987-02-05 09:00:00")
        repo = repo("test_commit_timestamp")
        repo.write_file("file")
        repo.commit(date: date)
        sha = Spoom::Git.last_commit(path: repo.path)
        assert_equal(date.strftime("%s").to_i, Spoom::Git.commit_timestamp(T.must(sha), path: repo.path))
        repo.destroy
      end

      def test_commit_date
        date = Time.parse("1987-02-05 09:00:00")
        repo = repo("test_commit_date")
        repo.write_file("file")
        repo.commit(date: date)
        sha = Spoom::Git.last_commit(path: repo.path)
        assert_equal(date, Spoom::Git.commit_date(T.must(sha), path: repo.path))
        repo.destroy
      end

      def test_git_diff
        repo = repo("test_git_diff")
        assert_equal("", Spoom::Git.diff("HEAD", path: repo.path).first)
        repo.write_file("file", "content")
        assert_equal("", Spoom::Git.diff("HEAD", path: repo.path).first)
        repo.commit
        assert_equal("", Spoom::Git.diff("HEAD", path: repo.path).first)
        repo.write_file("file", "content2")
        assert_match(/content2/, Spoom::Git.diff("HEAD", path: repo.path).first)
        repo.commit
        assert_equal("", Spoom::Git.diff("HEAD", path: repo.path).first)
        repo.destroy
      end

      def test_git_log
        repo = repo("test_git_log")
        repo.write_file("file")
        repo.commit(date: Time.parse("1987-02-05 09:00:00 +0000"))
        assert_equal("Thu Feb 5 09:00:00 1987 +0000", Spoom::Git.log("--format='format:%ad'", path: repo.path).first)
        repo.destroy
      end

      def test_git_rev_parse
        repo = repo("test_git_rev_parse")
        repo.write_file("file")
        repo.commit
        assert_match(/^[a-f0-9]+$/, Spoom::Git.rev_parse("master", path: repo.path).first.strip)
        repo.destroy
      end

      def test_git_show
        repo = repo("test_git_show")
        repo.write_file("file")
        repo.commit(date: Time.parse("1987-02-05 09:00:00"))
        assert_match(/Thu Feb 5 09:00:00 1987/, Spoom::Git.show(path: repo.path).first)
        repo.destroy
      end

      def test_sorbet_intro_not_found
        repo = repo("test_sorbet_intro_not_found")
        sha = Spoom::Git.sorbet_intro_commit(path: repo.path)
        assert_nil(sha)
        repo.destroy
      end

      def test_sorbet_intro_found
        repo = repo("test_sorbet_intro_found")
        repo.write_file("sorbet/config")
        repo.commit
        sha = Spoom::Git.sorbet_intro_commit(path: repo.path)
        assert(sha)
        repo.destroy
      end
    end
  end
end
