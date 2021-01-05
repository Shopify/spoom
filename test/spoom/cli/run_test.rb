# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Cli
    class RunTest < Minitest::Test
      include Spoom::TestHelper

      def setup
        @project = spoom_project("test_lsp")
        @project.sorbet_config(".")
        @project.write("file.rb", "# typed: true")
        @project.write("errors/errors.rb", <<~RB)
          # typed: true
          # frozen_string_literal: true

          class Foo
            sig { params(bar: Bar).returns(C) }
            def foo(bar)
            end
          end

          b = Foo.new(42)
          b.foo(b, c)
        RB
      end

      def teardown
        @project.destroy
      end

      def test_timeline_outside_sorbet_dir
        @project.remove("sorbet/config")
        out, err, status = @project.bundle_exec("spoom tc --no-color")
        assert_empty(out)
        assert_equal("Error: not in a Sorbet project (sorbet/config not found)", err.lines.first.chomp)
        refute(status)
      end

      def test_display_no_errors_without_filter
        @project.sorbet_config("file.rb")
        _, err, status = @project.bundle_exec("spoom tc")
        assert_equal(<<~MSG, err)
          No errors! Great job.
        MSG
        assert(status)
      end

      def test_display_no_errors_with_sort
        @project.sorbet_config("file.rb")
        _, err, status = @project.bundle_exec("spoom tc --no-color -s")
        assert_equal(<<~MSG, err)
          No errors! Great job.
        MSG
        assert(status)
      end

      def test_display_errors_with_bad_sort
        _, err, status = @project.bundle_exec("spoom tc --no-color -s bad")
        assert_equal(<<~MSG, err)
          Expected '--sort' to be one of code, loc; got bad
        MSG
        refute(status)
      end

      def test_display_errors_with_sort_default
        _, err, status = @project.bundle_exec("spoom tc --no-color -s")
        assert_equal(<<~MSG, err)
          5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
          5002 - errors/errors.rb:5: Unable to resolve constant `C`
          7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
          7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
          7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
          7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
          7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
          Errors: 7
        MSG
        refute(status)
      end

      def test_display_errors_with_sort_loc
        _, err, status = @project.bundle_exec("spoom tc --no-color -s loc")
        assert_equal(<<~MSG, err)
          5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
          5002 - errors/errors.rb:5: Unable to resolve constant `C`
          7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
          7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
          7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
          7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
          7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
          Errors: 7
        MSG
        refute(status)
      end

      def test_display_errors_with_sort_code
        _, err, status = @project.bundle_exec("spoom tc --no-color -s code")
        assert_equal(<<~MSG, err)
          5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
          5002 - errors/errors.rb:5: Unable to resolve constant `C`
          7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
          7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
          7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
          7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
          7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
          Errors: 7
        MSG
        refute(status)
      end

      def test_display_errors_with_sort_code_but_no_count
        _, err, status = @project.bundle_exec("spoom tc --no-color -s code --no-count")
        assert_equal(<<~MSG, err)
          5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
          5002 - errors/errors.rb:5: Unable to resolve constant `C`
          7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
          7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
          7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
          7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
          7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
        MSG
        refute(status)
      end

      def test_display_errors_with_limit
        _, err, status = @project.bundle_exec("spoom tc --no-color -s code -l 1")
        assert_equal(<<~MSG, err)
          5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
          Errors: 1 shown, 7 total
        MSG
        refute(status)
      end

      def test_display_errors_with_format
        _, err, status = @project.bundle_exec("spoom tc --no-color -s code -f '%F:%L %M %C'")
        assert_equal(<<~MSG, err)
          errors/errors.rb:5 Unable to resolve constant `Bar` 5002
          errors/errors.rb:5 Unable to resolve constant `C` 5002
          errors/errors.rb:5 Method `params` does not exist on `T.class_of(Foo)` 7003
          errors/errors.rb:5 Method `sig` does not exist on `T.class_of(Foo)` 7003
          errors/errors.rb:11 Method `c` does not exist on `T.class_of(<root>)` 7003
          errors/errors.rb:10 Wrong number of arguments for constructor. Expected: `0`, got: `1` 7004
          errors/errors.rb:11 Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2` 7004
          Errors: 7
        MSG
        refute(status)
      end

      def test_display_errors_with_format_partial
        _, err, status = @project.bundle_exec("spoom tc --no-color -s code -f '%F'")
        assert_equal(<<~MSG, err)
          errors/errors.rb
          errors/errors.rb
          errors/errors.rb
          errors/errors.rb
          errors/errors.rb
          errors/errors.rb
          errors/errors.rb
          Errors: 7
        MSG
        refute(status)
      end

      def test_display_errors_with_code
        _, err, status = @project.bundle_exec("spoom tc --no-color -c 7004")
        assert_equal(<<~MSG, err)
          7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
          7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
          Errors: 2 shown, 7 total
        MSG
        refute(status)
      end

      def test_display_errors_with_limit_and_code
        _, err, status = @project.bundle_exec("spoom tc --no-color -c 7004 -l 1")
        assert_equal(<<~MSG, err)
          7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
          Errors: 1 shown, 7 total
        MSG
        refute(status)
      end

      def test_display_errors_with_limit_and_code_but_no_count
        _, err, status = @project.bundle_exec("spoom tc --no-color -c 7004 -l 1 --no-count")
        assert_equal(<<~MSG, err)
          7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
        MSG
        refute(status)
      end

      def test_display_errors_with_path_option
        project = spoom_project("test_display_errors_with_path_option")
        _, err, status = project.bundle_exec("spoom tc --no-color -s code -l 1 -p #{@project.path}")
        assert_equal(<<~MSG, err)
          5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
          Errors: 1 shown, 7 total
        MSG
        refute(status)
        project.destroy
      end
    end
  end
end
