# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Indexer < Visitor
      extend T::Sig

      #: String
      attr_reader :path

      #: Index
      attr_reader :index

      #: (String path, Index index, ?plugins: Array[Plugins::Base]) -> void
      def initialize(path, index, plugins: [])
        super()

        @path = path
        @index = index
        @plugins = plugins
      end

      # Visit
    end
  end
end
