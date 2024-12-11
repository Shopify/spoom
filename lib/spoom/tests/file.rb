# typed: strict
# frozen_string_literal: true

module Spoom
  module Tests
    class File
      extend T::Sig

      sig { returns(String) }
      attr_accessor :path

      # TODO: add test cases
      # TODO: mapping?

      sig { params(path: String).void }
      def initialize(path)
        @path = path
      end
    end
  end
end
