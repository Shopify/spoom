# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Git
    class GitTest < TestWithProject
      def setup
        @project.git_init!
        @project.exec("git config user.name 'spoom-tests'")
        @project.exec("git config user.email 'spoom@shopify.com'")
      end

      def test_exec_with_unexisting_path
        e = assert_raises(Errno::ENOENT) do
          Spoom.exec("git ls", path: "/path/not/found")
        end
        assert_equal("No such file or directory - /path/not/found", e.message)
      end

      def test_last_commit_if_not_git_dir
        @project.remove!(".git")
        assert(Spoom::Git.last_commit(path: @project.absolute_path).nil?)
      end

      def test_last_commit_if_no_commit
        assert(Spoom::Git.last_commit(path: @project.absolute_path).nil?)
      end

      def test_last_commit
        @project.write!("file")
        @project.commit!

        sha = T.must(Spoom::Git.last_commit(path: @project.absolute_path)).sha
        assert(sha.size < 40)

        sha = T.must(Spoom::Git.last_commit(path: @project.absolute_path, short_sha: false)).sha
        assert(sha.size == 40)
      end

      def test_commit_timestamp
        time = Time.parse("1987-02-05 09:00:00")
        @project.write!("file")
        @project.commit!(time: time)
        last_commit = Spoom::Git.last_commit(path: @project.absolute_path)
        assert_equal(time.to_i, last_commit&.timestamp)
      end

      def test_commit_time
        time = Time.parse("1987-02-05 09:00:00")
        @project.write!("file")
        @project.commit!(time: time)
        last_commit = Spoom::Git.last_commit(path: @project.absolute_path)
        assert_equal(time, last_commit&.time)
      end

      def test_git_show
        @project.write!("file")
        @project.commit!(time: Time.parse("1987-02-05 09:00:00"))
        assert_match(/Thu Feb 5 09:00:00 1987/, Spoom::Git.show(path: @project.absolute_path).out)
      end

      def test_sorbet_intro_not_found
        commit = Spoom::Git.sorbet_intro_commit(path: @project.absolute_path)
        assert_nil(commit)
      end

      def test_sorbet_intro_found
        intro_time = Time.parse("1987-02-05 09:00:00 +0000")
        @project.write!("sorbet/config")
        @project.commit!(time: intro_time)
        commit = Spoom::Git.sorbet_intro_commit(path: @project.absolute_path)
        assert_match(/\A[a-z0-9]+\z/, commit&.sha)
        assert_equal(intro_time, commit&.time)
      end

      def test_sorbet_removal_not_found
        sha = Spoom::Git.sorbet_removal_commit(path: @project.absolute_path)
        assert_nil(sha)
      end

      def test_sorbet_removal_found
        intro_time = Time.parse("1987-02-05 09:00:00 +0000")
        removal_time = Time.parse("1987-02-05 21:00:00 +0000")
        @project.write!("sorbet/config")
        @project.commit!(time: intro_time)
        @project.remove!("sorbet/config")
        @project.commit!(time: removal_time)
        commit = Spoom::Git.sorbet_removal_commit(path: @project.absolute_path)
        assert_match(/\A[a-z0-9]+\z/, commit&.sha)
        assert_equal(removal_time, commit&.time)
      end
    end
  end
end
