# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class ErrorsTest < Minitest::Test
      def test_parses_empty_string
        errors = Spoom::Sorbet::Errors::Parser.parse_string("")
        assert_empty(errors)
      end

      def test_parses_no_errors
        errors = Spoom::Sorbet::Errors::Parser.parse_string("No errors! Great job.")
        assert_empty(errors)
      end

      def test_parses_a_token_error
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          lib/test/file.rb:80: unexpected token "end" https://srb.help/2001
              80 |end
                  ^^^
        ERR
        assert_equal(1, errors.size)

        error = T.must(errors.first)
        assert_equal("lib/test/file.rb", error.file)
        assert_equal(80, error.line)
        assert_equal("unexpected token \"end\"", error.message)
        assert_equal(2001, error.code)
        assert_equal(["80 |end", "^^^"], error.more.each(&:strip!))
      end

      def test_parses_a_redefinition_error
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          test.rb:100: Method Foo#initialize redefined without matching argument count. Expected: 0, got: 2 https://srb.help/4010
               100 |    class Foo < T::Struct
               101 |    end
              foo.rb:96: Previous definition
                96 |    class Foo < T::Struct
                97 |    end
        ERR
        assert_equal(1, errors.size)

        error = T.must(errors.first)
        assert_equal("test.rb", error.file)
        assert_equal(100, error.line)
        exp_message = "Method Foo#initialize redefined without matching argument count. Expected: 0, got: 2"
        assert_equal(exp_message, error.message)
        assert_equal(4010, error.code)
        assert_equal(<<~MORE, error.more.each(&:lstrip!).join(""))
          100 |    class Foo < T::Struct
          101 |    end
          foo.rb:96: Previous definition
          96 |    class Foo < T::Struct
          97 |    end
        MORE
      end

      def test_parses_a_method_missing_error
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          test.rb:105: Method foo does not exist on String https://srb.help/7003
               105 |        printer.print "foo".light_black
                                          ^^^^^^^^^^^^^^^^^
        ERR
        assert_equal(1, errors.size)

        error = T.must(errors.first)
        assert_equal("test.rb", error.file)
        assert_equal(105, error.line)
        assert_equal("Method foo does not exist on String", error.message)
        assert_equal(7003, error.code)
        assert_equal(<<~MORE, error.more.each(&:lstrip!).join(""))
          105 |        printer.print "foo".light_black
          ^^^^^^^^^^^^^^^^^
        MORE
      end

      def test_parses_a_not_enough_arguments_error
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          test.rb:28: Not enough arguments provided for method Foo#bar. Expected: 1..2, got: 1 https://srb.help/7004
              28 |              bar "hello"
                                ^^^^^^^^^^^
              test.rb:11: Foo#bar defined here
              11 |          def bar(title = "Error", name)
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        ERR
        assert_equal(1, errors.size)

        error = T.must(errors.first)
        assert_equal("test.rb", error.file)
        assert_equal(28, error.line)
        assert_equal("Not enough arguments provided for method Foo#bar. Expected: 1..2, got: 1", error.message)
        assert_equal(7004, error.code)
        assert_equal(<<~MORE, error.more.each(&:lstrip!).join(""))
          28 |              bar "hello"
          ^^^^^^^^^^^
          test.rb:11: Foo#bar defined here
          11 |          def bar(title = "Error", name)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        MORE
      end

      def test_parses_multiple_errors
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          a.rb:80: unexpected token "end" https://srb.help/2001
              80 |end
                  ^^^

          b.rb:28: Not enough arguments provided for method Foo#bar. Expected: 1..2, got: 1 https://srb.help/7004
              28 |              bar "hello"
                                ^^^^^^^^^^^
              test.rb:11: Foo#bar defined here
              11 |          def bar(title = "Error", name)
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

          c.rb:100: Method Foo#initialize redefined without matching argument count. Expected: 0, got: 2 https://srb.help/4010
               100 |    class Foo < T::Struct
               101 |    end
              foo.rb:96: Previous definition
                96 |    class Foo < T::Struct
                97 |    end


          d.rb:105: Method foo does not exist on String https://srb.help/7003
               105 |        printer.print "foo".light_black
                                          ^^^^^^^^^^^^^^^^^
        ERR
        assert_equal(4, errors.size)
        assert_equal(["a.rb", "b.rb", "c.rb", "d.rb"], errors.map(&:file))
        assert_equal([80, 28, 100, 105], errors.map(&:line))
        assert_equal([2001, 7004, 4010, 7003], errors.map(&:code))
      end

      def test_parses_no_errors_with_debug_string
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          👋 Hey there! Heads up that this is not a release build of sorbet.
          Release builds are faster and more well-supported by the Sorbet team.
          Check out the README to learn how to build Sorbet in release mode.
          To forcibly silence this error, either pass --silence-dev-message,
          or set SORBET_SILENCE_DEV_MESSAGE=1 in your shell environment.

          No errors! Great job.
        ERR
        assert_empty(errors)
      end

      def test_parses_errors_with_debug_string
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          👋 Hey there! Heads up that this is not a release build of sorbet.
          Release builds are faster and more well-supported by the Sorbet team.
          Check out the README to learn how to build Sorbet in release mode.
          To forcibly silence this error, either pass --silence-dev-message,
          or set SORBET_SILENCE_DEV_MESSAGE=1 in your shell environment.

          a.rb:80: unexpected token "end" https://srb.help/2001
              80 |end
                  ^^^

          b.rb:105: Method foo does not exist on String https://srb.help/7003
               105 |        printer.print "foo".light_black
                                          ^^^^^^^^^^^^^^^^^
        ERR
        assert_equal(2, errors.size)
        assert_equal(["a.rb", "b.rb"], errors.map(&:file))
        assert_equal([80, 105], errors.map(&:line))
        assert_equal([2001, 7003], errors.map(&:code))
      end

      def test_parses_errors_with_multiple_blank_lines
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          lib/a.rb:54: Method `foo` does not exist on `String` https://srb.help/7003
              54 |                x << io.string.foo
                                                 ^^^
            Autocorrect: Use `-a` to autocorrect
              lib/a.rb:54: Replace with `for`
              54 |                x << io.string.foo
                                                 ^^^


          lib/a.rb:55: Changing the type of a variable in a loop is not permitted https://srb.help/7001
              55 |                bar = !bar
                                         ^^^
            Existing variable has type: `FalseClass`
            Attempting to change type to: `TrueClass`

            Autocorrect: Use `-a` to autocorrect
              lib/a.rb:50: Replace with `T.let(false, T::Boolean)`
              50 |            bar = false
                                    ^^^^^

          lib/a.rb:64: Expected `T.any(TrueClass, FalseClass)` but found `String("")` for argument `x` https://srb.help/7002
              64 |            foo("")
                                  ^^
              lib/b.rb:1140: Method `Foo#foo (overload.1)` has specified `x` as `T.any(TrueClass, FalseClass)`
              1140 |        x: T.any(TrueClass, FalseClass),
                            ^
            Got String("") originating from:
              lib/a.rb:64:
              64 |            foo("")
                                  ^^
          Errors: 3
        ERR
        assert_equal(3, errors.size)
        assert_equal(["lib/a.rb", "lib/a.rb", "lib/a.rb"], errors.map(&:file))
        assert_equal([54, 55, 64], errors.map(&:line))
        assert_equal([7003, 7001, 7002], errors.map(&:code))
      end

      def test_sort_errors
        errors = Spoom::Sorbet::Errors::Parser.parse_string(<<~ERR)
          z.rb:80: unexpected token "end" https://srb.help/2001
              80 |end
                  ^^^

          b.rb:100: Method Foo#initialize redefined without matching argument count. Expected: 0, got: 2 https://srb.help/4010
               100 |    class Foo < T::Struct
               101 |    end
              foo.rb:96: Previous definition
                96 |    class Foo < T::Struct
                97 |    end

          b.rb:28: Not enough arguments provided for method Foo#bar. Expected: 1..2, got: 1 https://srb.help/7004
              28 |              bar "hello"
                                ^^^^^^^^^^^
              test.rb:11: Foo#bar defined here
              11 |          def bar(title = "Error", name)
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

          a.rb:105: Method foo does not exist on String https://srb.help/7003
               105 |        printer.print "foo".light_black
                                          ^^^^^^^^^^^^^^^^^
        ERR
        assert_equal(4, errors.size)
        assert_equal([7003, 7004, 4010, 2001], errors.sort.map(&:code))
      end
    end
  end
end
