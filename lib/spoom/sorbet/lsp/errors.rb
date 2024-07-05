# typed: strict
# frozen_string_literal: true

module Spoom
  module LSP
    class Error < Spoom::Error
      class AlreadyOpen < Error; end
      class BadHeaders < Error; end

      class Diagnostics < Error
        extend T::Sig

        sig { returns(String) }
        attr_reader :uri

        sig { returns(T::Array[Diagnostic]) }
        attr_reader :diagnostics

        class << self
          extend T::Sig

          sig { params(json: T::Hash[T.untyped, T.untyped]).returns(Diagnostics) }
          def from_json(json)
            Diagnostics.new(
              json["uri"],
              json["diagnostics"].map { |d| Diagnostic.from_json(d) },
            )
          end
        end

        sig { params(uri: String, diagnostics: T::Array[Diagnostic]).void }
        def initialize(uri, diagnostics)
          @uri = uri
          @diagnostics = diagnostics
          super()
        end
      end
    end

    class ResponseError < Error
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :code

      sig { returns(T::Hash[T.untyped, T.untyped]) }
      attr_reader :data

      class << self
        extend T::Sig

        sig { params(json: T::Hash[T.untyped, T.untyped]).returns(ResponseError) }
        def from_json(json)
          ResponseError.new(
            json["code"],
            json["message"],
            json["data"],
          )
        end
      end

      sig { params(code: Integer, message: String, data: T::Hash[T.untyped, T.untyped]).void }
      def initialize(code, message, data)
        super(message)
        @code = code
        @data = data
      end
    end
  end
end
