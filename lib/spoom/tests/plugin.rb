# typed: strict
# frozen_string_literal: true

module Spoom
  module Tests
    class Plugin
      extend T::Sig

      class << self
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { returns(String) }
        def framework_name
          T.must(name&.split("::")&.last)
        end

        sig { abstract.params(context: Context).returns(T::Boolean) }
        def match_context?(context); end

        sig { abstract.params(context: Context).returns(T::Array[Tests::File]) }
        def test_files(context); end

        sig { abstract.params(context: Context).void }
        def install!(context); end

        sig { abstract.params(context: Context, test_files: T::Array[Tests::File]).returns(T::Boolean) }
        def run_tests(context, test_files); end

        sig do
          abstract.params(context: Context, test_files: T::Array[Tests::File]).returns(Coverage)
        end
        def run_coverage(context, test_files); end
      end

      # def run_tests
      # end

      # def run_test
      # end
    end
  end
end

require_relative "plugins/minitest"
require_relative "plugins/rspec"
require_relative "plugins/active_support"

module Spoom
  module Tests
    DEFAULT_PLUGINS = T.let(
      [
        Plugins::Minitest,
        Plugins::RSpec,
        Plugins::ActiveSupport,
      ],
      T::Array[T.class_of(Plugin)],
    )
  end
end
