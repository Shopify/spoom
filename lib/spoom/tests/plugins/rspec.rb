# typed: strict
# frozen_string_literal: true

module Spoom
  module Tests
    module Plugins
      class RSpec < Plugin
        SPEC_ROOT = "spec"
        SPEC_GLOB = T.let("#{SPEC_ROOT}/**/*_spec.rb", String)

        class << self
          sig { override.params(context: Context).returns(T::Boolean) }
          def match_context?(context)
            context.glob(SPEC_GLOB).any?
          end

          sig { override.params(context: Context).returns(T::Array[Tests::File]) }
          def test_files(context)
            context.glob(SPEC_GLOB).map { |path| Tests::File.new(path) }
          end
        end
      end
    end
  end
end
