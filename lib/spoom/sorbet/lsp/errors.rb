# typed: true
# frozen_string_literal: true

module Spoom
  module LSP
    class Error < StandardError
      class AlreadyOpen < Error; end
      class BadHeaders < Error; end

      class Diagnostics < Error
        attr_reader :uri, :diagnostics

        def self.from_json(json)
          Diagnostics.new(
            json['uri'],
            json['diagnostics'].map { |d| Diagnostic.from_json(d) }
          )
        end

        def initialize(uri, diagnostics)
          @uri = uri
          @diagnostics = diagnostics
        end
      end
    end

    class ResponseError < Error
      attr_reader :code, :message, :data

      def self.from_json(json)
        ResponseError.new(
          json['code'],
          json['message'],
          json['data']
        )
      end

      def initialize(code, message, data)
        @code = code
        @message = message
        @data = data
      end
    end
  end
end
