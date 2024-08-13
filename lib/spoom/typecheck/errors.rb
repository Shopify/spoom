# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    module Errors
      class Error
        extend T::Sig

        sig { returns(Integer) }
        attr_reader :code

        sig { returns(String) }
        attr_reader :message

        sig { returns(Location) }
        attr_reader :location

        sig { params(code: Integer, message: String, location: Location).void }
        def initialize(code, message, location)
          @code = code
          @message = message
          @location = location
        end
      end
    end

    # Internal - 1000

    # Parser - 2000

    ERROR_PARSER = T.let(Error.new(100), Error)

    # Desugar - 3000
    # Rewrite - 3000
    # Namer - 4000
    # Resolver - 5000
    # CFG - 6000
    # Infer - 7000
  end
end
