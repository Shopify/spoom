# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Context
    class SorbetTest < Minitest::Test
      def test_context_write_sorbet_config!
        context = Context.mktmp!

        assert_raises(Errno::ENOENT) do
          context.read_sorbet_config
        end

        context.write_sorbet_config!(".")
        assert_equal(".", context.read_sorbet_config)

        context.destroy!
      end

      def test_context_srb
        context = Context.mktmp!

        context.write!("a.rb", <<~RB)
          # typed: true

          foo(42)
        RB

        res = context.srb("tc")
        refute(res.status)

        context.write_gemfile!(<<~GEMFILE)
          source "https://rubygems.org"

          gem "sorbet"
        GEMFILE
        context.bundle_install!

        res = context.srb("tc")
        refute(res.status)

        context.write_sorbet_config!(".")
        res = context.srb("tc")
        assert_equal(<<~ERR, res.err)
          a.rb:3: Method `foo` does not exist on `T.class_of(<root>)` https://srb.help/7003
               3 |foo(42)
                  ^^^
          Errors: 1
        ERR
        refute(res.status)

        context.write!("b.rb", <<~RB)
          def foo(value); end
        RB

        res = context.srb("tc")
        assert(res.status)

        context.destroy!
      end

      def test_context_file_strictness
        context = Context.mktmp!

        assert_nil(context.read_file_strictness("a.rb"))

        context.write!("a.rb", "")
        assert_nil(context.read_file_strictness("a.rb"))

        context.write!("a.rb", "# typed: true\n")
        assert_equal("true", context.read_file_strictness("a.rb"))

        context.destroy!
      end
    end
  end
end
