# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class SigilsTest < Minitest::Test
      def test_sigil_nonempty
        sigil = Sigils.sigil("false")
        assert_equal("# typed: false", sigil)
      end

      def test_sigil_empty
        sigil = Sigils.sigil("")
        assert_equal("# typed: ", sigil)
      end

      def test_valid_strictness_ignore
        content  = <<~STR
          # typed: ignore
          class A; end
        STR

        assert(Sigils.valid_strictness?(content))
      end

      def test_valid_strictness_false
        content  = <<~STR
          # typed: false
          class A; end
        STR

        assert(Sigils.valid_strictness?(content))
      end

      def test_valid_strictness_true
        content  = <<~STR
          # typed: true
          class A; end
        STR

        assert(Sigils.valid_strictness?(content))
      end

      def test_valid_strictness_strict
        content  = <<~STR
          # typed: strict
          class A; end
        STR

        assert(Sigils.valid_strictness?(content))
      end

      def test_valid_strictness_strong
        content  = <<~STR
          # typed: strong
          class A; end
        STR

        assert(Sigils.valid_strictness?(content))
      end

      def test_valid_strictness_invalid_return_false
        content  = <<~STR
          # typed: asdf
          class A; end
        STR

        refute(Sigils.valid_strictness?(content))
      end

      def test_valid_strictness_none_return_false
        content  = <<~STR
          class A; end
        STR

        refute(Sigils.valid_strictness?(content))
      end

      def test_strictness_return_ignore
        content  = <<~STR
          # typed: ignore
          class A; end
        STR

        strictness = Sigils.strictness(content)

        assert_equal("ignore", strictness)
      end

      def test_strictness_return_false
        content  = <<~STR
          # typed: false
          class A; end
        STR

        strictness = Sigils.strictness(content)

        assert_equal("false", strictness)
      end

      def test_strictness_return_true
        content  = <<~STR
          # typed: true
          class A; end
        STR

        strictness = Sigils.strictness(content)

        assert_equal("true", strictness)
      end

      def test_strictness_return_strict
        content  = <<~STR
          # typed: strict
          class A; end
        STR

        strictness = Sigils.strictness(content)

        assert_equal("strict", strictness)
      end

      def test_strictness_return_strong
        content  = <<~STR
          # typed: strong
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_equal(strictness, "strong")
      end

      def test_strictness_no_sigil
        content  = <<~STR
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_nil(strictness)
      end

      def test_strictness_invalid_sigil_return
        content  = <<~STR
          #typed: no
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_equal("no", strictness)
      end

      def test_strictness_empty
        content = <<~STR
          # typed:
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_equal("", strictness)
      end

      def test_strictness_first_valid_return
        content  = <<~STR
          # typed: true
          # typed: strict
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_equal("true", strictness)
      end

      def test_strictness_first_invalid_return
        content  = <<~STR
          # typed: no
          # typed: strict
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_equal("no", strictness)
      end

      def test_update_sigil_to_use_valid_strictness
        content = <<~STR
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "false")

        strictness = Sigils.strictness(new_content)

        assert_equal("false", strictness)
      end

      def test_update_sigil_to_use_invalid_strictness
        content = <<~STR
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "asdf")

        strictness = Sigils.strictness(new_content)

        assert_equal("asdf", strictness)
      end

      def test_update_sigil_first_of_multiple
        content = <<~STR
          # typed: strong
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "true")

        assert(/^# typed: ignore$/.match?(new_content))

        strictness = Sigils.strictness(new_content)

        assert_equal("true", strictness)
      end
    end
  end
end
