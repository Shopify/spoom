# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    module Translate
      class ValidatorTest < Minitest::Test
        def test_validate_returns_true_if_landmarks_did_not_move
          assert_valid_translation(
            original: <<~RUBY,
              # original comment 1
              class C; end
              # original comment 2
              module M; end
              # original comment 3
              def m; end
              # original comment 4
              __LINE__
            RUBY
            rewritten: <<~RUBY,
              # different comment 1
              class C; end
              # different comment 2
              module M; end
              # different comment 3
              def m; end
              # different comment 4
              __LINE__
            RUBY
          )
        end

        def test_validate_returns_false_if_landmarks_moved
          # Each snippet is pushed down a line in the rewrite, so its landmark is
          # expected on line 1 but actually lands on line 2.
          assert_translation_diff(
            original: <<~RUBY,
              class C; end
              module M; end
              def m; end
              __LINE__
            RUBY
            rewritten: <<~RUBY,
              # This new comment pushes everything down a line!
              class C; end
              module M; end
              def m; end
              __LINE__
            RUBY
            on_wrong_line: [
              { landmark_id: "class C", expected: [1], actual: [2] },
              { landmark_id: "module M", expected: [2], actual: [3] },
              { landmark_id: "def m", expected: [3], actual: [4] },
              { landmark_id: "__LINE__", expected: [4], actual: [5] },
            ],
          )
        end

        def test_validate_returns_false_if_landmarks_disappeared
          assert_translation_diff(
            original: <<~RUBY,
              class C; end
              module M; end
              def m; end
              __LINE__
            RUBY
            rewritten: <<~RUBY,
              # They're all gone!
            RUBY
            is_missing: [
              { landmark_id: "class C", line: 1 },
              { landmark_id: "module M", line: 2 },
              { landmark_id: "def m", line: 3 },
              { landmark_id: "__LINE__", line: 4 },
            ],
          )
        end

        def test_validate_returns_false_if_landmarks_appeared
          assert_translation_diff(
            original: <<~RUBY,
              # Nothing was here before.
            RUBY
            rewritten: <<~RUBY,
              class NewClass; end
              module NewModule; end
              def new_method; end
              __LINE__
            RUBY
            has_excess: [
              { landmark_id: "class NewClass", line: 1 },
              { landmark_id: "module NewModule", line: 2 },
              { landmark_id: "def new_method", line: 3 },
              { landmark_id: "__LINE__", line: 4 },
            ],
          )
        end

        def test_does_not_confuse_different_entities_with_same_landmark_id
          # Our validator uses simple names as the landmark IDs, but the definition's line number removes ambiguity. In
          # this example, B, C and d all have the same ID despite having different fully qualified names. The validator
          # still catches this scenario because the surrounding module changes

          assert_translation_diff(
            original: <<~RUBY,
              module First
                class B; end
                module C; end
                def d; end
              end
              module Second
                class B; end
                module C; end
                def d; end
              end
            RUBY
            rewritten: <<~RUBY,
              module First
                class B; end
                module C; end
                def d; end
              end
              module Third
                class B; end
                module C; end
                def d; end
              end
            RUBY
            is_missing: [{ landmark_id: "module Second", line: 6 }],
            has_excess: [{ landmark_id: "module Third", line: 6 }],
          )
        end

        private

        def assert_valid_translation(original:, rewritten:)
          # A translation is valid when there's nothing missing, excess, or on the wrong line.
          assert_translation_diff(original:, rewritten:, is_missing: [], has_excess: [], on_wrong_line: [])
        end

        def assert_translation_diff(original:, rewritten:, is_missing: [], has_excess: [], on_wrong_line: [])
          missing = is_missing
          excess = has_excess

          result = Validator.validate(original, rewritten)

          assert_equal(missing, result.missing_from_rewritten_output, <<~MSG)
            Unexpected `missing_from_rewritten_output`.\n#{result.pretty_inspect}
          MSG

          assert_equal(excess, result.excess_in_rewritten_output, <<~MSG)
            Unexpected `excess_in_rewritten_output`.\n#{result.pretty_inspect}
          MSG

          assert_equal(on_wrong_line, result.on_wrong_line, <<~MSG)
            Unexpected `on_wrong_line`.\n#{result.pretty_inspect}
          MSG

          # Sanity check the `#valid?` predicate
          if missing.empty? && excess.empty? && on_wrong_line.empty?
            assert_predicate(result, :valid?)
          else
            refute_predicate(result, :valid?)
          end
        end
      end
    end
  end
end
