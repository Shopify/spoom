# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    module Srb
      class AnnotationsTest < TestWithProject
        def setup
          @project.bundle_install!
        end

        def test_translate_from_rbi_to_rbs
          @project.write!("a/file1.rb", <<~RB)
            x = T.let(nil, T.nilable(String))
          RB

          result = @project.spoom("srb annotations translate --no-color")
          assert_empty(result.err)
          assert_equal(<<~OUT, result.out)
            Translating annotations from `rbi` to `rbs` in `1` file...

            Translated annotations in `1` file.
          OUT
          assert(result.status)

          assert_equal(<<~RB, File.read(@project.absolute_path_to("a/file1.rb")))
            x = nil #: String?
          RB
        end

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
      end
    end
  end
end
