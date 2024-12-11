# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Tests
    class TestTest < TestWithProject
      extend T::Sig

      def test_guess_framework_raises_if_cant_guess
        context = Context.mktmp!

        assert_raises(Tests::CantGuessTestFramework) do
          Tests.guess_framework(context)
        end

        context.destroy!
      end

      def test_guess_framework_raises_if_too_many_plugins_match
        context = Context.mktmp!
        context.write!("test/foo_test.rb", "")
        context.write!("spec/bar_spec.rb", "")

        assert_raises(Tests::CantGuessTestFramework) do
          Tests.guess_framework(context)
        end

        context.destroy!
      end
    end
  end
end
