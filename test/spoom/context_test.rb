# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class ContextTest < Minitest::Test
      def test_context_mktmp!
        context = Context.mktmp!
        assert(context.exist?)
        context.destroy!
      end

      def test_context_make!
        context = Context.new("/tmp/spoom-context-test")
        refute(context.exist?)
        context.mkdir!
        assert(context.exist?)
        context.destroy!
        refute(context.exist?)
      end

      def test_context_gemfile
        context = Context.mktmp!
        context.write_gemfile!("CONTENTS")
        assert(context.file?("Gemfile"))
        assert_equal("CONTENTS", context.read_gemfile)
        context.destroy!
      end

      def test_context_bundle
        context = Context.mktmp!

        res = context.bundle("-v")
        assert(res.status)

        res = context.bundle("-v", version: "9999999999.99999.999")
        refute(res.status)

        context.destroy!
      end

      def test_context_bundle_install!
        context = Context.mktmp!

        res = context.bundle("install")
        assert_empty(res.out)
        assert_equal("Could not locate Gemfile\n", res.err)
        refute(res.status)

        context.write_gemfile!(<<~GEMFILE)
          source "https://rubygems.org"

          gem "ansi"
        GEMFILE

        res = context.bundle("install")
        assert(res.status)

        context.destroy!
      end

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

      def test_context_git_last_commit
        context = Context.mktmp!
        assert_nil(context.git_last_commit)

        context.git_init!
        context.git("config user.name 'John Doe'")
        context.git("config user.email 'john@doe.org'")

        context.git("-c commit.gpgsign=false commit -m '#{message}' --allow-empty")

        sha = T.must(context.git_last_commit).sha
        assert(sha.size < 40)

        sha = T.must(context.git_last_commit(short_sha: false)).sha
        assert(sha.size == 40)

        context.destroy!
      end

      def test_context_write_sorbet_config!
        context = Context.mktmp!

        assert_raises(Errno::ENOENT) do
          context.read_sorbet_config
        end

        context.write_sorbet_config!(".")
        assert_equal(".", context.read_sorbet_config)

        context.destroy!
      end

      def test_context_srb
        context = Context.mktmp!

        context.write!("a.rb", <<~RB)
          # typed: true

          foo(42)
        RB

        res = context.srb("tc")
        refute(res.status)

        context.write_gemfile!(<<~GEMFILE)
          source "https://rubygems.org"

          gem "sorbet"
        GEMFILE
        context.bundle_install!

        res = context.srb("tc")
        refute(res.status)

        context.write_sorbet_config!(".")
        res = context.srb("tc")
        assert_equal(<<~ERR, res.err)
          a.rb:3: Method `foo` does not exist on `T.class_of(<root>)` https://srb.help/7003
               3 |foo(42)
                  ^^^
          Errors: 1
        ERR
        refute(res.status)

        context.write!("b.rb", <<~RB)
          def foo(value); end
        RB

        res = context.srb("tc")
        assert(res.status)

        context.destroy!
      end

      def test_context_file_strictness
        context = Context.mktmp!

        assert_nil(context.read_file_strictness("a.rb"))

        context.write!("a.rb", "")
        assert_nil(context.read_file_strictness("a.rb"))

        context.write!("a.rb", "# typed: true\n")
        assert_equal("true", context.read_file_strictness("a.rb"))

        context.destroy!
      end
    end
  end
end
