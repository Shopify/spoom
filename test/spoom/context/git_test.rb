# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Context
    class GitTest < Minitest::Test
      def test_context_git_init!
        context = Context.mktmp!

        res = context.git("log")
        assert_empty(res.out)
        assert_equal("fatal: not a git repository (or any of the parent directories): .git\n", res.err)
        refute(res.status)

        res = context.git_init!(branch: "main")
        path = File.realdirpath(context.absolute_path)
        assert_equal("Initialized empty Git repository in #{path}/.git/", res.out.strip)
        assert_empty(res.err)
        assert(res.status)

        res = context.git("log")
        assert_empty(res.out)
        assert_equal("fatal: your current branch 'main' does not have any commits yet\n", res.err)
        refute(res.status)

        context.destroy!
      end

      def test_context_git_checkout!
        context = Context.mktmp!
        context.git_init!(branch: "a")
        context.git("config user.name 'John Doe'")
        context.git("config user.email 'john@doe.org'")

        context.write!("a", "")
        context.git("add a")
        context.git("-c commit.gpgsign=false commit -m 'a'")

        context.git("checkout -b b")
        context.write!("b", "")
        context.git("add b")
        context.git("-c commit.gpgsign=false commit -m 'b'")

        res = context.git_checkout!(ref: "a")
        assert(res.status)
        assert(context.file?("a"))
        refute(context.file?("b"))

        res = context.git_checkout!(ref: "b")
        assert(res.status)
        assert(context.file?("b"))
        assert(context.file?("b"))

        context.destroy!
      end

      def test_context_git_current_branch
        context = Context.mktmp!
        assert_nil(context.git_current_branch)

        context.git_init!(branch: "main")
        assert_equal("main", context.git_current_branch)
        context.git("checkout -b other")
        assert_equal("other", context.git_current_branch)

        context.destroy!
      end

      def test_context_git_diff
        context = Context.mktmp!

        context.git_init!
        context.exec("git config user.name 'spoom-tests'")
        context.exec("git config user.email 'spoom@shopify.com'")

        assert_equal("", context.git_diff("HEAD").out)
        context.write!("file", "content")
        assert_equal("", context.git_diff("HEAD").out)
        context.git_commit!
        assert_equal("", context.git_diff("HEAD").out)
        context.write!("file", "content2")
        assert_match(/content2/, context.git_diff("HEAD").out)
        context.git_commit!
        assert_equal("", context.git_diff("HEAD").out)

        context.destroy!
      end

      def test_context_git_last_commit_if_not_git_dir
        context = Context.mktmp!

        assert_nil(context.git_last_commit)

        context.destroy!
      end

      def test_context_git_last_commit_if_no_commit
        context = Context.mktmp!
        context.git_init!

        assert_nil(context.git_last_commit)

        context.destroy!
      end

      def test_context_git_last_commit
        context = Context.mktmp!
        assert_nil(context.git_last_commit)

        time = Time.parse("1987-02-05 09:00:00")
        context.git_init!
        context.git("config user.name 'John Doe'")
        context.git("config user.email 'john@doe.org'")

        context.git_commit!(allow_empty: true, time: time)

        sha = T.must(context.git_last_commit).sha
        assert(sha.size < 40)

        sha = T.must(context.git_last_commit(short_sha: false)).sha
        assert(sha.size == 40)

        last_commit = context.git_last_commit
        assert_equal(time.to_i, last_commit&.timestamp)
        assert_equal(time, last_commit&.time)

        context.destroy!
      end

      def test_context_git_log
        context = Context.mktmp!
        context.git_init!
        context.git("config user.name 'John Doe'")
        context.git("config user.email 'john@doe.org'")
        context.write!("file")
        context.git_commit!(time: Time.parse("1987-02-05 09:00:00 +0000"))

        log = context.git_log("--format='format:%ad'").out
        assert_equal("Thu Feb 5 09:00:00 1987 +0000", log)

        context.destroy!
      end

      def test_context_clean_workdir_on_clean_repo
        context = Context.mktmp!
        context.git_init!
        context.exec("git config user.name 'spoom-tests'")
        context.exec("git config user.email 'spoom@shopify.com'")
        context.write!("file")
        context.git_commit!

        assert(context.git_workdir_clean?)

        context.destroy!
      end

      def test_context_clean_workdir_on_dirty_repo
        context = Context.mktmp!
        context.git_init!
        context.exec("git config user.name 'spoom-tests'")
        context.exec("git config user.email 'spoom@shopify.com'")
        context.write!("file", "content1")
        context.git_commit!
        context.write!("file", "content2")

        refute(context.git_workdir_clean?)

        context.destroy!
      end
    end
  end
end
