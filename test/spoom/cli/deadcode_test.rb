# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    class DeadcodeTest < TestWithProject
      def test_deadcode_without_deadcode
        @project.write!("lib/foo.rb", <<~RUBY)
          def foo; end
          def bar; end
          def baz; end

          foo; bar; baz
        RUBY

        result = @project.spoom("deadcode --no-color")
        assert_equal(<<~ERR, result.err)
          Collecting files...
          Indexing 1 files...
          Analyzing 3 definitions against 3 references...

          No dead code found!
        ERR
        assert_empty(result.out)
        assert(result.status)
      end

      def test_deadcode_with_deadcode
        @project.write!("lib/foo.rb", <<~RUBY)
          def foo; end
          def bar; end
          def baz; end
          foo; bar
        RUBY

        result = @project.spoom("deadcode --no-color")
        assert_equal(<<~ERR, result.err)
          Collecting files...
          Indexing 1 files...
          Analyzing 3 definitions against 2 references...

          Candidates:
            baz lib/foo.rb:3:0-3:12

            Found 1 dead candidates
        ERR
        assert_empty(result.out)
        refute(result.status)
      end

      def test_deadcode_show_files
        @project.write!("lib/foo.rb", <<~RUBY)
          def foo; end
          def bar; end
          def baz; end
        RUBY

        @project.write!("lib/bar.rb", <<~RUBY)
          foo; bar; baz
        RUBY

        result = @project.spoom("deadcode --show-files --no-color")
        assert_equal(<<~ERR, result.err)
          Collecting files...

          Collected 2 files for analysis
            lib/bar.rb
            lib/foo.rb

          Indexing 2 files...
          Analyzing 3 definitions against 3 references...

          No dead code found!
        ERR
        assert_empty(result.out)
        assert(result.status)
      end

      def test_deadcode_show_defs
        @project.write!("lib/foo.rb", <<~RUBY)
          def foo; end
          def bar; end
          def baz; end

          foo; bar; baz
        RUBY

        result = @project.spoom("deadcode --show-defs --no-color")
        assert_equal(<<~ERR, result.err)
          Collecting files...
          Indexing 1 files...

          Definitions:
            foo
              method lib/foo.rb:1:0-1:12
            bar
              method lib/foo.rb:2:0-2:12
            baz
              method lib/foo.rb:3:0-3:12

          Analyzing 3 definitions against 3 references...

          No dead code found!
        ERR
        assert_empty(result.out)
        assert(result.status)
      end

      def test_deadcode_show_refs
        @project.write!("lib/foo.rb", <<~RUBY)
          def foo; end
          def bar; end
          def baz; end

          foo; bar; baz
        RUBY

        result = @project.spoom("deadcode --show-refs --no-color")
        assert_equal(<<~ERR, result.err)
          Collecting files...
          Indexing 1 files...

          References:
            bar method lib/foo.rb:5:5-5:8
            baz method lib/foo.rb:5:10-5:13
            foo method lib/foo.rb:5:0-5:3

          Analyzing 3 definitions against 3 references...

          No dead code found!
        ERR
        assert_empty(result.out)
        assert(result.status)
      end

      def test_deadcode_show_plugins_default
        result = @project.spoom("deadcode --show-plugins --no-color")
        assert_equal(<<~ERR, result.err)
          Collecting files...

          Loaded 6 plugins
            Spoom::Deadcode::Plugins::Namespaces
            Spoom::Deadcode::Plugins::Ruby
            Spoom::Deadcode::Plugins::Minitest
            Spoom::Deadcode::Plugins::Rake
            Spoom::Deadcode::Plugins::Sorbet
            Spoom::Deadcode::Plugins::Thor

          Indexing 0 files...
          Analyzing 0 definitions against 0 references...

          No dead code found!
        ERR
        assert_empty(result.out)
        assert(result.status)
      end

      def test_remove
        @project.write!("lib/foo.rb", <<~RUBY)
          def foo; end
          def bar; end
          def baz; end
        RUBY

        result = @project.spoom("deadcode remove lib/foo.rb:2:0-2:12 --no-color")

        assert_equal(<<~ERR, result.err)
          @@ -1,3 +1,2 @@
           def foo; end
          -def bar; end
           def baz; end
        ERR

        assert_empty(result.out)
        assert(result.status)
      end
    end
  end
end
