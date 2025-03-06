# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    module Srb
      class SigsTest < TestWithProject
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

        # translate

        def test_only_supports_translation_from_rbi
          result = @project.spoom("srb sigs translate --from rbs")

          assert_equal(<<~ERR, result.err)
            Expected '--from' to be one of rbi; got rbs
          ERR
          refute(result.status)
        end

        def test_only_supports_translation_to_rbs
          result = @project.spoom("srb sigs translate --to rbi")

          assert_equal(<<~ERR, result.err)
            Expected '--to' to be one of rbs; got rbi
          ERR
          refute(result.status)
        end

        def test_no_files
          result = @project.spoom("srb sigs translate --no-color")

          assert_equal(<<~OUT, result.err)
            Error: No files to transform
          OUT
          refute(result.status)
        end

        def test_only_selected_files
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

        def test_encoding_support
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
      end
    end
  end
end
