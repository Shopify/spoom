# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class ContextTest < Minitest::Test
      def test_context_mktmp!
        context = Context.mktmp!
        assert(context.exist?)
        context.destroy!
      end

      def test_context_make!
        context = Context.new("/tmp/spoom-context-test")
        refute(context.exist?)
        context.mkdir!
        assert(context.exist?)
        context.destroy!
        refute(context.exist?)
      end
    end
  end
end
