# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class ConfigTest < Minitest::Test
      def test_parses_empty_config_strings
        config = Spoom::Sorbet::Config.parse_string("")
        assert_empty(config.paths)
        assert_empty(config.ignore)
        assert_empty(config.allowed_extensions)
      end

      def test_parses_a_simple_config_string
        config = Spoom::Sorbet::Config.parse_string(".")
        assert_equal(["."], config.paths)
        assert_empty(config.ignore)
        assert_empty(config.allowed_extensions)
      end

      def test_parses_a_config_string_with_paths
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          lib/a
          lib/b
        CONFIG
        assert_equal(["lib/a", "lib/b"], config.paths)
        assert_empty(config.ignore)
        assert_empty(config.allowed_extensions)
      end

      def test_parses_a_config_string_with_file_options
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          a
          --file=b
          c
          --file
          d
          e
        CONFIG
        assert_equal(["a", "b", "c", "d", "e"], config.paths)
        assert_empty(config.ignore)
        assert_empty(config.allowed_extensions)
      end

      def test_parses_a_config_string_with_dir_options
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          a
          --dir=b
          c
          --dir
          d
          e
        CONFIG
        assert_equal(["a", "b", "c", "d", "e"], config.paths)
        assert_empty(config.ignore)
      end

      def test_parses_a_config_string_with_ignore_options
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          a
          --ignore=b
          c
          --ignore
          d
          e
        CONFIG
        assert_equal(["a", "c", "e"], config.paths)
        assert_equal(["b", "d"], config.ignore)
        assert_empty(config.allowed_extensions)
      end

      def test_parses_a_config_string_with_other_options
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          a
          --other=b
          c
          --d
          d
          e
          -f
        CONFIG
        assert_equal(["a", "c", "e"], config.paths)
        assert_empty(config.ignore)
        assert_empty(config.allowed_extensions)
      end

      def test_parses_a_config_string_with_no_stdlib
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          a
          b
          --no-stdlib
          c
        CONFIG
        assert_equal(["a", "b", "c"], config.paths)
        assert(config.no_stdlib)
      end

      def test_parses_a_config_string_with_mixed_options
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          a
          --other=b
          --file
          c
          --d
          e
          --dir=f
          -g
          --dir
          h
          --file=i
          --ignore
          j
          --ignore=k
          l
          m
          -n
          --o
          p
        CONFIG
        assert_equal(["a", "c", "f", "h", "i", "l", "m"], config.paths)
        assert_equal(["j", "k"], config.ignore)
        assert_empty(config.allowed_extensions)
      end

      def test_parses_a_config_string_with_mixed_options_comments_and_empty_lines
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          a
          --other=b
          # This is a comment.
          --file
          c

          --d
          e
          --dir=f
          -g
          --dir

          h
          --file=i
          --ignore
          # Comment in between.
          j
          --ignore=k
          l
          m
          -n
          --o
          p
        CONFIG
        assert_equal(["a", "c", "f", "h", "i", "l", "m"], config.paths)
        assert_equal(["j", "k"], config.ignore)
        assert_empty(config.allowed_extensions)
      end

      def test_parses_a_real_config_string
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          .
          --error-black-list=4002
          --ignore=.git/
          --ignore=.idea/
          --ignore=vendor/
          --allowed-extension=.rb
          --allowed-extension=.rbi
          --allowed-extension=.rake
          --allowed-extension=.ru
          --no-stdlib
        CONFIG
        assert_equal(["."], config.paths)
        assert_equal([".git/", ".idea/", "vendor/"], config.ignore)
        assert_equal([".rb", ".rbi", ".rake", ".ru"], config.allowed_extensions)
        assert(config.no_stdlib)
      end

      def test_parses_a_config_file_with_errors
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          .
          --error-black-list
          --ignore
          --ignore
          .idea/
          --ignore
          --allowed-extension
          --allowed-extension
          --allowed-extension=.rake
          --allowed-extension
          --allowed-extension
          .ru
        CONFIG
        assert_equal(["."], config.paths)
        assert_equal([".idea/"], config.ignore)
        assert_equal([".rake", ".ru"], config.allowed_extensions)
      end

      def test_options_string_empty
        config = Spoom::Sorbet::Config.parse_string("")
        assert_equal("", config.options_string)
      end

      def test_options_string_with_options
        config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
          .
          --ignore=.git/
          --ignore=vendor/
          --allowed-extension=.rb
          --no-stdlib
        CONFIG
        assert_equal(". --ignore .git/ --ignore vendor/ --allowed-extension .rb --no-stdlib", config.options_string)
      end
    end
  end
end
