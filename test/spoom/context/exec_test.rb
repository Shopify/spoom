# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Context
    class ExecTest < Minitest::Test
      def test_context_exec
        context = Context.mktmp!

        assert_raises(Errno::ENOENT) do
          context.exec("command/not/found")
        end

        res = context.exec("echo 'Hello, world!'")
        assert_equal("Hello, world!\n", res.out)
        assert_empty(res.err)
        assert(res.status)

        res = context.exec("echo 'Hello, world!' >&2")
        assert_empty(res.out)
        assert_equal("Hello, world!\n", res.err)
        assert(res.status)

        res = context.exec("ls not/found")
        refute(res.status)

        context.destroy!
      end
    end
  end
end
