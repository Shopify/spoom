# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class ContextTest < Minitest::Test
      def test_context_mktmp!
        context = Context.mktmp!

        assert(File.directory?(context.absolute_path))

        context.destroy!
      end

      def test_context_make!
        context = Context.new("/tmp/spoom-context-test")
        refute(File.directory?(context.absolute_path))
        context.mkdir!
        assert(File.directory?(context.absolute_path))
        context.destroy!
        refute(File.directory?(context.absolute_path))
      end

      def test_context_glob
        context = Context.mktmp!
        context.write!("a.rb", "")
        context.write!("b/b.rbi", "")
        context.write!("b/c/c.rbi", "")
        context.write!("d.rb", "")

        assert_equal(["a.rb", "b", "b/b.rbi", "b/c", "b/c/c.rbi", "d.rb"], context.glob)
        assert_equal(["a.rb", "b/b.rbi", "b/c/c.rbi", "d.rb"], context.glob("**/*.rb*"))
        assert_equal(["b/b.rbi", "b/c/c.rbi"], context.glob("b/**/*.rbi"))

        context.destroy!
      end

      def test_context_list
        context = Context.mktmp!
        context.write!("a.rb", "")
        context.write!("b/b.rbi", "")
        context.write!("b/c/c.rbi", "")
        context.write!("d.rb", "")

        assert_equal(["a.rb", "b", "d.rb"], context.list)

        context.destroy!
      end

      def test_context_file?
        context = Context.mktmp!

        refute(context.file?("a.rb"))
        context.write!("a.rb", "")
        assert(context.file?("a.rb"))
        context.remove!("a.rb")
        refute(context.file?("a.rb"))

        context.destroy!
      end

      def test_context_read
        context = Context.mktmp!

        assert_raises(Errno::ENOENT) { context.read("a.rb") }
        context.write!("a.rb", "CONTENTS")
        assert_equal("CONTENTS", context.read("a.rb"))

        context.destroy!
      end

      def test_context_write!
        context = Context.mktmp!

        context.write!("a.rb", "CONTENTS")
        assert_equal("CONTENTS", context.read("a.rb"))

        context.write!("a.rb", "NEW CONTENTS")
        assert_equal("NEW CONTENTS", context.read("a.rb"))

        context.write!("a.rb", "\nMORE CONTENTS", append: true)
        assert_equal("NEW CONTENTS\nMORE CONTENTS", context.read("a.rb"))

        context.destroy!
      end

      def test_context_remove!
        context = Context.mktmp!

        context.remove!("path/not/found") # Nothing raised

        context.write!("a.rb")
        assert(context.file?("a.rb"))
        context.remove!("a.rb")
        refute(context.file?("a.rb"))

        context.write!("a/b/c/d.rb")
        assert(context.file?("a/b/c/d.rb"))
        context.remove!("a")
        refute(context.file?("a.rb"))

        context.destroy!
      end

      def test_context_move!
        context = Context.mktmp!

        assert_raises(Errno::ENOENT) do
          context.move!("path/not/found", "another/not/found")
        end

        context.write!("a/b/c/d.rb")
        context.move!("a/b/c/d.rb", "another/not/found")
        refute(context.file?("a/b/c/d.rb"))
        assert(context.file?("another/not/found"))

        context.write!("a/b/c/d.rb")
        context.move!("a/b", "a/x")
        refute(context.file?("a/b/c/d.rb"))
        assert(context.file?("a/x/c/d.rb"))

        context.write!("a/b/c/d.rb")
        context.move!("a/b/c/d.rb", "d.rb")
        refute(context.file?("a/b/c/d.rb"))
        assert(context.file?("d.rb"))

        context.destroy!
      end

      def test_context_exec
        context = Context.mktmp!

        assert_raises(Errno::ENOENT) do
          context.exec("command/not/found")
        end

        res = context.exec("echo 'Hello, world!'")
        assert_equal("Hello, world!\n", res.out)
        assert_empty(res.err)
        assert(res.status)

        res = context.exec("echo 'Hello, world!' >&2")
        assert_empty(res.out)
        assert_equal("Hello, world!\n", res.err)
        assert(res.status)

        res = context.exec("ls not/found")
        refute(res.status)

        context.destroy!
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

        context.git_init!

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

        context.git_init!
        assert_equal("main", context.git_current_branch)

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
