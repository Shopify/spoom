# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class File
      extend T::Sig

      sig { params(path: String).void }
      def initialize(path)
        @path = path
        @tree = T.let(nil, T.nilable(Tree))
      end
    end
  end
end
