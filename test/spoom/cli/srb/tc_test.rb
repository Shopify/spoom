# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    module Srb
      class TcTest < TestWithProject
        def setup
          @project.bundle_install!
          @project.write!("file.rb", "# typed: true")
          @project.write!("errors/errors.rb", <<~RB)
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

        def test_timeline_outside_sorbet_dir
          @project.remove!("sorbet/config")
          result = @project.spoom("srb tc --no-color")
          assert_empty(result.out)
          assert_equal("Error: not in a Sorbet project (`sorbet/config` not found)", result.err&.lines&.first&.chomp)
          refute(result.status)
        end

        def test_display_no_errors_without_filter
          @project.write_sorbet_config!("file.rb")
          result = @project.spoom("srb tc")
          assert_equal(<<~MSG, result.err)
            No errors! Great job.
          MSG
          assert(result.status)
        end

        def test_display_no_errors_with_sort
          @project.write_sorbet_config!("file.rb")
          result = @project.spoom("srb tc --no-color -s")
          assert_equal(<<~MSG, result.err)
            No errors! Great job.
          MSG
          assert(result.status)
        end

        def test_display_errors_with_bad_sort
          result = @project.spoom("srb tc --no-color -s bad")
          assert_equal(<<~MSG, result.err)
            Expected '--sort' to be one of code, loc; got bad
          MSG
          refute(result.status)
        end

        def test_display_errors_with_sort_default
          result = @project.spoom("srb tc --no-color -s")
          assert_equal(<<~MSG, result.err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            5002 - errors/errors.rb:5: Unable to resolve constant `C`
            7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
            Errors: 7
          MSG
          refute(result.status)
        end

        def test_display_errors_with_sort_default_with_custom_url
          @project.write_sorbet_config!(<<~CONFIG)
            .
            --error-url-base=https://custom#
          CONFIG
          result = @project.spoom("srb tc --no-color -s")
          assert_equal(<<~MSG, result.err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            5002 - errors/errors.rb:5: Unable to resolve constant `C`
            7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
            Errors: 7
          MSG
          refute(result.status)
        end

        def test_display_errors_with_sort_loc
          result = @project.spoom("srb tc --no-color -s loc")
          assert_equal(<<~MSG, result.err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            5002 - errors/errors.rb:5: Unable to resolve constant `C`
            7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
            Errors: 7
          MSG
          refute(result.status)
        end

        def test_display_errors_with_sort_code
          result = @project.spoom("srb tc --no-color -s code")
          assert_equal(<<~MSG, result.err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            5002 - errors/errors.rb:5: Unable to resolve constant `C`
            7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
            Errors: 7
          MSG
          refute(result.status)
        end

        def test_display_errors_with_sort_code_but_no_count
          result = @project.spoom("srb tc --no-color -s code --no-count")
          assert_equal(<<~MSG, result.err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            5002 - errors/errors.rb:5: Unable to resolve constant `C`
            7003 - errors/errors.rb:5: Method `params` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:5: Method `sig` does not exist on `T.class_of(Foo)`
            7003 - errors/errors.rb:11: Method `c` does not exist on `T.class_of(<root>)`
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
          MSG
          refute(result.status)
        end

        def test_display_errors_with_limit
          result = @project.spoom("srb tc --no-color -s code -l 1")
          assert_equal(<<~MSG, result.err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            Errors: 1 shown, 7 total
          MSG
          refute(result.status)
        end

        def test_display_errors_with_format
          result = @project.spoom("srb tc --no-color -s code -f '%F:%L %M %C'")
          assert_equal(<<~MSG, result.err)
            errors/errors.rb:5 Unable to resolve constant `Bar` 5002
            errors/errors.rb:5 Unable to resolve constant `C` 5002
            errors/errors.rb:5 Method `params` does not exist on `T.class_of(Foo)` 7003
            errors/errors.rb:5 Method `sig` does not exist on `T.class_of(Foo)` 7003
            errors/errors.rb:11 Method `c` does not exist on `T.class_of(<root>)` 7003
            errors/errors.rb:10 Wrong number of arguments for constructor. Expected: `0`, got: `1` 7004
            errors/errors.rb:11 Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2` 7004
            Errors: 7
          MSG
          refute(result.status)
        end

        def test_display_errors_with_format_partial
          result = @project.spoom("srb tc --no-color -s code -f '%F'")
          assert_equal(<<~MSG, result.err)
            errors/errors.rb
            errors/errors.rb
            errors/errors.rb
            errors/errors.rb
            errors/errors.rb
            errors/errors.rb
            errors/errors.rb
            Errors: 7
          MSG
          refute(result.status)
        end

        def test_display_errors_with_format_and_uniq
          result = @project.spoom("srb tc --no-color -s code -f '%F' --no-count -u")
          assert_equal(<<~MSG, result.err)
            errors/errors.rb
          MSG
          refute(result.status)
        end

        def test_display_errors_with_code
          result = @project.spoom("srb tc --no-color -c 7004")
          assert_equal(<<~MSG, result.err)
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            7004 - errors/errors.rb:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`
            Errors: 2 shown, 7 total
          MSG
          refute(result.status)
        end

        def test_display_errors_with_limit_and_code
          result = @project.spoom("srb tc --no-color -c 7004 -l 1")
          assert_equal(<<~MSG, result.err)
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
            Errors: 1 shown, 7 total
          MSG
          refute(result.status)
        end

        def test_display_errors_with_limit_and_code_but_no_count
          result = @project.spoom("srb tc --no-color -c 7004 -l 1 --no-count")
          assert_equal(<<~MSG, result.err)
            7004 - errors/errors.rb:10: Wrong number of arguments for constructor. Expected: `0`, got: `1`
          MSG
          refute(result.status)
        end

        def test_display_errors_from_path
          @project = new_project
          @project.write!("path_a/file1.rb", <<~RB)
            # typed: true
            foo
          RB
          @project.write!("path_a/file2.rb", <<~RB)
            # typed: true
            bar
          RB
          @project.write!("path_b/file1.rb", <<~RB)
            # typed: true
            baz
          RB

          result = @project.spoom("srb tc --no-color")
          assert_equal(<<~MSG, result.err)
            7003 - path_a/file1.rb:2: Method `foo` does not exist on `T.class_of(<root>)`
            7003 - path_a/file2.rb:2: Method `bar` does not exist on `T.class_of(<root>)`
            7003 - path_b/file1.rb:2: Method `baz` does not exist on `T.class_of(<root>)`
            Errors: 3
          MSG
          refute(result.status)

          result = @project.spoom("srb tc --no-color path_a/file1.rb")
          assert_equal(<<~MSG, result.err)
            7003 - path_a/file1.rb:2: Method `foo` does not exist on `T.class_of(<root>)`
            Errors: 1 shown, 3 total
          MSG
          refute(result.status)

          result = @project.spoom("srb tc --no-color path_a")
          assert_equal(<<~MSG, result.err)
            7003 - path_a/file1.rb:2: Method `foo` does not exist on `T.class_of(<root>)`
            7003 - path_a/file2.rb:2: Method `bar` does not exist on `T.class_of(<root>)`
            Errors: 2 shown, 3 total
          MSG
          refute(result.status)

          result = @project.spoom("srb tc --no-color path_a/file1.rb path_b/file1.rb")
          assert_equal(<<~MSG, result.err)
            7003 - path_a/file1.rb:2: Method `foo` does not exist on `T.class_of(<root>)`
            7003 - path_b/file1.rb:2: Method `baz` does not exist on `T.class_of(<root>)`
            Errors: 2 shown, 3 total
          MSG
          refute(result.status)
        end

        def test_display_errors_with_path_option
          project = new_project("test_display_errors_with_path_option_2")
          result = project.spoom("srb tc --no-color -s code -l 1 -p #{@project.absolute_path}")
          assert_equal(<<~MSG, result.err)
            5002 - errors/errors.rb:5: Unable to resolve constant `Bar`
            Errors: 1 shown, 7 total
          MSG
          refute(result.status)
          project.destroy!
        end

        def test_output_no_errors_to_junit_xml
          @project.write_sorbet_config!("file.rb")
          result = @project.spoom("srb tc --junit_output_path=junit.xml")
          expected_doc = <<~XML.chomp
            <?xml version='1.0'?>
            <testsuite name='Sorbet' failures='0'>
              <testcase name='Typecheck' tests='1'/>
            </testsuite>
          XML
          assert_equal(expected_doc, @project.read("junit.xml"))
          assert(result.status)
        end

        def test_output_errors_to_junit_xml
          result = @project.spoom("srb tc --junit_output_path=junit.xml")
          expected_doc = <<~XML.chomp
            <?xml version='1.0'?>
            <testsuite name='Sorbet' failures='7'>
              <testcase name='Unable to resolve constant `Bar`' file='errors/errors.rb' line='5'>
                <failure type='5002'>
                  <![CDATA[In file errors/errors.rb:
                 5 |  sig { params(bar: Bar).returns(C) }
                                        ^^^
              Did you mean `Dir`? Use `-a` to autocorrect
                errors/errors.rb:5: Replace with `Dir`
                 5 |  sig { params(bar: Bar).returns(C) }
                                        ^^^
                <GIT_LINK>/rbi/core/dir.rbi#L11: `Dir` defined here
                11 |class Dir < Object
                    ^^^^^^^^^^^^^^^^^^]]>
                </failure>
              </testcase>
              <testcase name='Unable to resolve constant `C`' file='errors/errors.rb' line='5'>
                <failure type='5002'>
                  <![CDATA[In file errors/errors.rb:
                 5 |  sig { params(bar: Bar).returns(C) }
                                                     ^
              Did you mean `T`? Use `-a` to autocorrect
                errors/errors.rb:5: Replace with `T`
                 5 |  sig { params(bar: Bar).returns(C) }
                                                     ^
                <GIT_LINK>/rbi/sorbet/t.rbi#L16: `T` defined here
                16 |module T
                    ^^^^^^^^
              Did you mean `GC`? Use `-a` to autocorrect
                errors/errors.rb:5: Replace with `GC`
                 5 |  sig { params(bar: Bar).returns(C) }
                                                     ^
                <GIT_LINK>/rbi/core/gc.rbi#L12: `GC` defined here
                12 |module GC
                    ^^^^^^^^^]]>
                </failure>
              </testcase>
              <testcase name='Method `params` does not exist on `T.class_of(Foo)`' file='errors/errors.rb' line='5'>
                <failure type='7003'>
                  <![CDATA[In file errors/errors.rb:
                 5 |  sig { params(bar: Bar).returns(C) }
                            ^^^^^^]]>
                </failure>
              </testcase>
              <testcase name='Method `sig` does not exist on `T.class_of(Foo)`' file='errors/errors.rb' line='5'>
                <failure type='7003'>
                  <![CDATA[In file errors/errors.rb:
                 5 |  sig { params(bar: Bar).returns(C) }
                      ^^^
              Autocorrect: Use `-a` to autocorrect
                errors/errors.rb:5: Insert `extend T::Sig`
                 5 |  sig { params(bar: Bar).returns(C) }
                    ^]]>
                </failure>
              </testcase>
              <testcase name='Wrong number of arguments for constructor. Expected: `0`, got: `1`' file='errors/errors.rb' line='10'>
                <failure type='7004'>
                  <![CDATA[In file errors/errors.rb:
                10 |b = Foo.new(42)
                                ^^
                <GIT_LINK>/rbi/core/basic_object.rbi#L230: `initialize` defined here
                 230 |  def initialize(); end
                        ^^^^^^^^^^^^^^^^
              Autocorrect: Use `-a` to autocorrect
                errors/errors.rb:10: Delete
                10 |b = Foo.new(42)
                                ^^]]>
                </failure>
              </testcase>
              <testcase name='Method `c` does not exist on `T.class_of(&lt;root&gt;)`' file='errors/errors.rb' line='11'>
                <failure type='7003'>
                  <![CDATA[In file errors/errors.rb:
                11 |b.foo(b, c)
                             ^]]>
                </failure>
              </testcase>
              <testcase name='Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2`' file='errors/errors.rb' line='11'>
                <failure type='7004'>
                  <![CDATA[In file errors/errors.rb:
                11 |b.foo(b, c)
                             ^
                errors/errors.rb:6: `foo` defined here
                 6 |  def foo(bar)
                      ^^^^^^^^^^^^
              Autocorrect: Use `-a` to autocorrect
                errors/errors.rb:11: Delete
                11 |b.foo(b, c)
                           ^^^]]>
                </failure>
              </testcase>
            </testsuite>
          XML

          output_xml = @project.read("junit.xml")
            .gsub(%r{^(\s+)https://github\.com/sorbet/sorbet/tree/[0-9a-f]+}, '\1<GIT_LINK>')

          assert_equal(expected_doc, output_xml)
          refute(result.status)
        end

        def test_pass_options_to_sorbet
          result = @project.spoom("srb tc --no-color --sorbet-options \"--no-config -e 'foo'\"")
          assert_equal(<<~MSG, result.err)
            7003 - -e:1: Method `foo` does not exist on `T.class_of(<root>)`
            Errors: 1
          MSG
          refute(result.status)
        end

        def test_display_sorbet_segfault
          # Create a fake Sorbet that will segfault
          @project.write!("mock_sorbet", <<~RB)
            #!/usr/bin/env ruby
            $stderr.puts "segfault"
            exit(#{Spoom::Sorbet::SEGFAULT_CODE})
          RB
          @project.exec("chmod +x mock_sorbet")

          # Any file will segfault with this
          @project.write!("will_segfault.rb", <<~RB)
            # typed: true
            foo
          RB

          result = @project.spoom("srb tc --no-color --sorbet #{@project.absolute_path}/mock_sorbet")
          assert_equal(<<~OUT, result.err)
            !!! Sorbet exited with code 139 - SEGFAULT !!!

            This is most likely related to a bug in Sorbet.
          OUT
          refute(result.status)
        end

        def test_display_sorbet_killed
          # Create a fake Sorbet that will segfault
          @project.write!("mock_sorbet", <<~RB)
            #!/usr/bin/env ruby
            $stderr.puts "segfault"
            exit(#{Spoom::Sorbet::KILLED_CODE})
          RB
          @project.exec("chmod +x mock_sorbet")

          # Any file will segfault with this
          @project.write!("will_segfault.rb", <<~RB)
            # typed: true
            foo
          RB

          result = @project.spoom("srb tc --no-color --sorbet #{@project.absolute_path}/mock_sorbet")
          assert_equal(<<~OUT, result.err)
            !!! Sorbet exited with code 137 - KILLED !!!
          OUT
          refute(result.status)
        end

        def test_display_sorbet_error
          result = @project.spoom("srb tc --no-color --sorbet-options=\"--not-found\"")
          assert_equal(<<~MSG, result.err)
            Option ‘not-found’ does not exist. To see all available options pass `--help`.
          MSG
          refute(result.status)
        end

        def test_deprecated_command_spoom_tc
          @project.remove!("errors")
          result = @project.spoom("tc --no-color")
          assert_equal(<<~MSG, result.err)
            Warning: This command is deprecated. Please use `spoom srb tc` instead.
            No errors! Great job.
          MSG
          assert(result.status)
        end
      end
    end
  end
end
