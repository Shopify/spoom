# typed: strict
# frozen_string_literal: true

require "rbi"
require "ext/prism"

module Spoom
  module Typecheck
    class Error < Spoom::Error
      extend T::Sig

      sig { returns(Location) }
      attr_reader :location

      sig { params(message: String, location: Location).void }
      def initialize(message, location)
        super("#{location}: #{message}")

        @location = location
      end
    end
  end
end

require "spoom/typecheck/printer"
require "spoom/typecheck/empty"
require "spoom/typecheck/namer"
require "spoom/typecheck/resolver"
require "spoom/typecheck/cfg"
require "spoom/typecheck/infer"
