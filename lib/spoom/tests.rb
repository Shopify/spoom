# typed: strict
# frozen_string_literal: true

require "coverage"

module Spoom
  module Tests
    class Error < Spoom::Error; end
  end
end

require_relative "tests/file"
require_relative "tests/case"
require_relative "tests/coverage"
require_relative "tests/plugin"

module Spoom
  module Tests
    class CantGuessTestFramework < Error; end

    class << self
      extend T::Sig

      sig { params(context: Context, try_frameworks: T::Array[T.class_of(Plugin)]).returns(T.class_of(Plugin)) }
      def guess_framework(context, try_frameworks: DEFAULT_PLUGINS)
        frameworks = try_frameworks.select { |plugin| plugin.match_context?(context) }

        case frameworks.size
        when 0
          raise CantGuessTestFramework,
            "No framework found for context. Tried #{try_frameworks.map(&:framework_name).join(", ")}"
        when 1
          return T.must(frameworks.first)
        when 2
          if frameworks.include?(Plugins::ActiveSupport) && frameworks.include?(Plugins::Minitest)
            return Plugins::ActiveSupport
          end
        end

        raise CantGuessTestFramework, "Multiple frameworks matching context: #{frameworks.map(&:name).join(", ")}"
      end
    end
  end
end
