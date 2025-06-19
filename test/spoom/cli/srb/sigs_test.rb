# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    module Srb
      class SigsTest < TestWithProject
        GEMSPEC = <<~RB
          Gem::Specification.new do |spec|
            spec.name          = "foo"
            spec.version       = "0.0.1"
            spec.authors       = ["Alexandre Terrasa"]
            spec.summary       = "Some text."
          end
        RB

        def setup
          @project.bundle_install!
        end

        # strip

        def test_strip_sigs
          @project.write!("a/file1.rb", <<~RB)
            sig { void }
            def foo; end

            class B
              sig { void }
              def bar; end
            end
          RB

          result = @project.spoom("srb sigs strip --no-color")

          assert_equal(<<~OUT, result.out)
            Stripping signatures from `1` file...

            Stripped signatures from `1` file.
          OUT
          assert(result.status)

          assert_equal(<<~RB, @project.read("a/file1.rb"))
            def foo; end

            class B
              def bar; end
            end
          RB
        end

        # translate --from rbi --to rbs

        def test_translate_from_and_to_cannot_be_the_same
          result = @project.spoom("srb sigs translate --from rbs --to rbs --no-color")
          assert_equal(<<~ERR, result.err)
            Error: Can't translate signatures from `rbs` to `rbs`
          ERR
          refute(result.status)

          result = @project.spoom("srb sigs translate --from rbi --to rbi --no-color")
          assert_equal(<<~ERR, result.err)
            Error: Can't translate signatures from `rbi` to `rbi`
          ERR
          refute(result.status)
        end

        def test_translate_no_files
          result = @project.spoom("srb sigs translate --no-color")

          assert_equal(<<~OUT, result.err)
            Error: No files found
          OUT
          refute(result.status)
        end

        def test_translate_only_selected_files
          @project.write!("a/file1.rb", <<~RB)
            sig { void }
            def foo; end
          RB

          @project.write!("a/file2.rb", <<~RB)
            sig { void }
            def foo; end
          RB

          @project.write!("b/file1.rb", <<~RB)
            sig { void }
            def foo; end
          RB

          result = @project.spoom("srb sigs translate --no-color a/file1.rb b/")

          assert_empty(result.err)
          assert_equal(<<~OUT, result.out)
            Translating signatures from `rbi` to `rbs` in `2` files...

            Translated signatures in `2` files.
          OUT
          assert(result.status)

          assert_equal(<<~RB, @project.read("a/file1.rb"))
            #: -> void
            def foo; end
          RB

          assert_equal(<<~RB, @project.read("a/file2.rb"))
            sig { void }
            def foo; end
          RB

          assert_equal(<<~RB, @project.read("b/file1.rb"))
            #: -> void
            def foo; end
          RB
        end

        def test_translate_encoding_support
          utf8_path = @project.absolute_path_to("file.rb")
          File.write(utf8_path, <<~RB)
            # 👋
            sig { void }
            def foo; end
          RB

          iso8859_1_path = @project.absolute_path_to("file_iso_8859_1.rb")
          File.write(iso8859_1_path, <<~RB, encoding: Encoding::ISO8859_1)
            # encoding: ISO-8859-1

            # Some content with accentuated characters: éàèù
            sig { void }
            def foo; end
          RB

          result = @project.spoom("srb sigs translate --no-color")

          assert_empty(result.err)
          assert_equal(<<~OUT, result.out)
            Translating signatures from `rbi` to `rbs` in `2` files...

            Translated signatures in `2` files.
          OUT
          assert(result.status)

          contents = File.read(utf8_path, encoding: Encoding::UTF_8)
          assert_equal(<<~RB, contents)
            # 👋
            #: -> void
            def foo; end
          RB

          contents = File.read(iso8859_1_path, encoding: Encoding::ISO8859_1)
          assert_equal(<<~RB.encode(Encoding::ISO8859_1), contents)
            # encoding: ISO-8859-1

            # Some content with accentuated characters: éàèù
            #: -> void
            def foo; end
          RB
        end

        def test_translate_without_positional_names
          @project.write!("file.rb", <<~RB)
            sig { params(a: Integer, b: Integer, c: Integer, d: Integer, e: Integer, f: Integer).void }
            def foo(a, b = 42, *c, d:, e: 42, **f); end
          RB

          result = @project.spoom("srb sigs translate --no-color file.rb --no-positional-names")

          assert_empty(result.err)
          assert(result.status)

          assert_equal(<<~RB, @project.read("file.rb"))
            #: (Integer, ?Integer, *Integer, d: Integer, ?e: Integer, **Integer f) -> void
            def foo(a, b = 42, *c, d:, e: 42, **f); end
          RB
        end

        def test_translate_includes_rbi_files
          @project.write!("file.rb", <<~RB)
            sig { void }
            def foo; end
          RB

          @project.write!("file.rbi", <<~RB)
            sig { void }
            def foo; end
          RB

          result = @project.spoom("srb sigs translate --no-color --include-rbi-files")

          assert_empty(result.err)
          assert(result.status)

          assert_equal(<<~RB, @project.read("file.rb"))
            #: -> void
            def foo; end
          RB

          assert_equal(<<~RB, @project.read("file.rbi"))
            #: -> void
            def foo; end
          RB
        end

        def test_translate_to_rbs_with_max_line_length_error
          result = @project.spoom("srb sigs translate --no-color --max-line-length -1")

          assert_equal(<<~ERR, result.err)
            Error: --max-line-length can't be negative
          ERR
          refute(result.status)
        end

        def test_translate_to_rbs_with_max_line_length_by_default
          @project.write!("file.rb", <<~RB)
            sig do
              params(
                param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
                param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
              ).void
            end
            def foo(param1:, param2:); end
          RB

          result = @project.spoom("srb sigs translate --no-color")

          assert_empty(result.err)
          assert(result.status)

          assert_equal(<<~RB, @project.read("file.rb"))
            #: (
            #|   param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
            #|   param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
            #| ) -> void
            def foo(param1:, param2:); end
          RB
        end

        def test_translate_to_rbs_without_max_line_length
          @project.write!("file.rb", <<~RB)
            sig do
              params(
                param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
                param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
              ).void
            end
            def foo(param1:, param2:); end
          RB

          result = @project.spoom("srb sigs translate --no-color --max-line-length 0")

          assert_empty(result.err)
          assert(result.status)

          assert_equal(<<~RB, @project.read("file.rb"))
            #: (param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType, param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType) -> void
            def foo(param1:, param2:); end
          RB
        end

        def test_translate_to_rbs_translate_generics_option
          contents = <<~RB
            class A
              extend T::Generic

              E = type_member
            end
          RB

          @project.write!("file.rb", contents)

          result = @project.spoom("srb sigs translate --no-color --from rbs --to rbi")

          assert_empty(result.err)
          assert(result.status)
          assert_equal(contents, @project.read("file.rb"))

          result = @project.spoom("srb sigs translate --no-color --from rbi --to rbs --translate-generics")

          assert_empty(result.err)
          assert(result.status)
          assert_equal(<<~RB, @project.read("file.rb"))
            #: [E]
            class A
            end
          RB
        end

        def test_translate_to_rbs_translate_helpers_option
          contents = <<~RB
            class A
              extend T::Helpers

              abstract!
            end
          RB

          @project.write!("file.rb", contents)

          result = @project.spoom("srb sigs translate --no-color --from rbi --to rbs")

          assert_empty(result.err)
          assert(result.status)
          assert_equal(contents, @project.read("file.rb"))

          result = @project.spoom("srb sigs translate --no-color --from rbi --to rbs --translate-helpers")

          assert_empty(result.err)
          assert(result.status)
          assert_equal(<<~RB, @project.read("file.rb"))
            # @abstract
            class A
            end
          RB
        end

        def test_translate_to_rbs_translate_abstract_methods_option
          contents = <<~RB
            class A
              sig { abstract.void }
              def foo; end
            end
          RB

          @project.write!("file.rb", contents)

          result = @project.spoom("srb sigs translate --no-color --from rbi --to rbs")

          assert_empty(result.err)
          assert(result.status)
          assert_equal(contents, @project.read("file.rb"))

          result = @project.spoom("srb sigs translate --no-color --from rbi --to rbs --translate-abstract-methods")

          assert_empty(result.err)
          assert(result.status)
          assert_equal(<<~RB, @project.read("file.rb"))
            class A
              # @abstract
              #: -> void
              def foo = raise NotImplementedError, "Abstract method called"
            end
          RB
        end

        # translate --from rbs --to rbi

        def test_translate_from_rbs_to_rbi
          @project.write!("file.rb", <<~RB)
            #: -> void
            def foo; end
          RB

          result = @project.spoom("srb sigs translate --from rbs --to rbi --no-color")

          assert_empty(result.err)
          assert_equal(<<~OUT, result.out)
            Translating signatures from `rbs` to `rbi` in `1` file...

            Translated signatures in `1` file.
          OUT
          assert(result.status)

          assert_equal(<<~RB, @project.read("file.rb"))
            sig { void }
            def foo; end
          RB
        end

        def test_translate_to_rbi_with_max_line_length_by_default
          @project.write!("file.rb", <<~RB)
            #: (
            #|   param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
            #|   param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
            #| ) -> void
            def foo(param1:, param2:); end
          RB

          result = @project.spoom("srb sigs translate --no-color --from rbs --to rbi")

          assert_empty(result.err)
          assert(result.status)

          assert_equal(<<~RB, @project.read("file.rb"))
            sig do
              params(
                param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
                param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
              ).void
            end
            def foo(param1:, param2:); end
          RB
        end

        def test_translate_to_rbi_without_max_line_length
          @project.write!("file.rb", <<~RB)
            #: (
            #|   param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType,
            #|   param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType
            #| ) -> void
            def foo(param1:, param2:); end
          RB

          result = @project.spoom("srb sigs translate --no-color --from rbs --to rbi --max-line-length 0")

          assert_empty(result.err)
          assert(result.status)

          assert_equal(<<~RB, @project.read("file.rb"))
            sig { params(param1: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType, param2: AVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongType).void }
            def foo(param1:, param2:); end
          RB
        end

        # export

        def test_export_no_gemspec
          result = @project.spoom("srb sigs export --no-color")

          assert_equal(<<~ERR, result.err)
            Error: No gemspec file found
          ERR

          refute(result.status)
        end

        def test_export_cant_locate_entry_point
          @project.write!("foo.gemspec", GEMSPEC)
          @project.write!("lib/bar.rb", "")

          result = @project.spoom("srb sigs export --no-color")

          assert_equal(<<~ERR, result.err)
            Error: No entry point found at `lib/foo.rb`
          ERR

          refute(result.status)
        end

        def test_export_create_rbi_file
          @project.write!("foo.gemspec", GEMSPEC)
          @project.write!("lib/foo.rb", <<~RB)
            class Foo
              # ignored comment
              #: -> void
              def foo; end
            end
          RB

          result = @project.spoom("srb sigs export --no-color")

          assert_empty(result.err)
          assert(result.status)
          assert(@project.file?("rbi/foo.rbi"))
          assert_equal(<<~RBI, @project.read("rbi/foo.rbi"))
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for types exported from the `foo` gem.
            # Please instead update this file by running `bundle exec spoom srb sigs export`.

            class Foo
              sig { void }
              def foo; end
            end
          RBI
        end

        def test_export_check_sync_raises_if_rbi_is_not_up_to_date
          @project.write!("foo.gemspec", GEMSPEC)
          @project.write!("lib/foo.rb", <<~RB)
            class Foo
              #: -> void
              def bar; end

              #: -> void
              def foo; end
            end
          RB

          rbi = <<~RBI
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for types exported from the `foo` gem.
            # Please instead update this file by running `bundle exec spoom srb sigs export`.

            class Foo
              sig { void }
              def foo; end
            end
          RBI

          @project.write!("rbi/foo.rbi", rbi)

          result = @project.spoom("srb sigs export --no-color --check-sync")
          refute(result.status)
          assert_equal(<<~ERR.rstrip, result.err&.lines&.map(&:rstrip)&.join("\n"))
            --- generated
            +++ current
            @@ -6,8 +6,5 @@

             class Foo
               sig { void }
            -  def bar; end
            -
            -  sig { void }
               def foo; end
             end

            Error: The RBI file at `rbi/foo.rbi` is not up to date

            Please run `bundle exec spoom srb sigs export` to update it.
          ERR

          # Original RBI file is not modified
          assert_equal(rbi, @project.read("rbi/foo.rbi"))
        end

        def test_export_check_sync_does_not_raise_if_rbi_is_up_to_date
          @project.write!("foo.gemspec", GEMSPEC)
          @project.write!("lib/foo.rb", <<~RB)
            class Foo
              #: -> void
              def bar; end

              #: -> void
              def foo; end
            end
          RB

          rbi = <<~RBI
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for types exported from the `foo` gem.
            # Please instead update this file by running `bundle exec spoom srb sigs export`.

            class Foo
              sig { void }
              def bar; end

              sig { void }
              def foo; end
            end
          RBI

          @project.write!("rbi/foo.rbi", rbi)

          result = @project.spoom("srb sigs export --no-color --check-sync")
          assert(result.status)
          assert_empty(result.err)
          assert_equal("The RBI file at `rbi/foo.rbi` is up to date", result.out.lines.last&.strip)
        end
      end
    end
  end
end
