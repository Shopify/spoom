# typed: true
# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/spoom/file_tree.rb"

require "stringio"

module Spoom
  module Sorbet
    class FileTreeTest < Minitest::Test
      include Spoom::TestHelper

      def test_empty_file_tree_contains_no_path
        tree = Spoom::FileTree.new
        assert(tree.paths.empty?)
      end

      def test_file_tree_one_root
        tree = Spoom::FileTree.new(["a.rb"])
        paths = ["a.rb"]
        assert_equal(paths, tree.paths)
      end

      def test_file_tree_multiple_roots
        tree = Spoom::FileTree.new(["a.rb", "b.rb", "c"])
        paths = ["a.rb", "b.rb", "c"]
        assert_equal(paths, tree.paths)
      end

      def test_file_tree_from_a_path
        tree = Spoom::FileTree.new(["a/b.rb"])
        paths = ["a", "a/b.rb"]
        assert_equal(paths, tree.paths)
      end

      def test_file_tree_from_a_long_path
        tree = Spoom::FileTree.new(["a/b/c/d/e.rb"])
        paths = ["a", "a/b", "a/b/c", "a/b/c/d", "a/b/c/d/e.rb"]
        assert_equal(paths, tree.paths)
      end

      def test_file_tree_printer
        tree = Spoom::FileTree.new([
          "a/b/c/d/e1.rb",
          "a/b/c/d/e2.rb",
          "a/b.rb",
          "a/b/c.rb",
          "b/c/d/e.rb",
        ])
        out = StringIO.new
        tree.print(out: out, show_strictness: false, colors: false)
        assert_equal(<<~EXP, out.string)
          a/
            b/
              c/
                d/
                  e1.rb
                  e2.rb
              c.rb
            b.rb
          b/
            c/
              d/
                e.rb
        EXP
      end

      def test_file_tree_printer_strip_prefix
        project = new_project
        project.write!("a/b/c/d/e1.rb", "# typed: true")
        project.write!("a/b/c/d/e2.rb", "# typed: false")
        project.write!("a/b/c.rb", "# typed: strict")
        project.write!("a/b.rb")
        tree = Spoom::FileTree.new(project.glob, strip_prefix: project.absolute_path)
        out = StringIO.new
        tree.print(out: out, colors: false)
        assert_equal(<<~EXP, out.string)
          Gemfile
          a/
            b/
              c/
                d/
                  e1.rb (true)
                  e2.rb (false)
              c.rb (strict)
            b.rb
          sorbet/
            config
        EXP
      end
    end
  end
end
