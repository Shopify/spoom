# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Context
    class FileSystemTest < Minitest::Test
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
    end
  end
end
