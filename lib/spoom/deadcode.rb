# typed: strict
# frozen_string_literal: true

require "erubi"
require "prism"

require_relative "deadcode/visitor"
require_relative "deadcode/erb"
require_relative "deadcode/index"
require_relative "deadcode/indexer"

require_relative "deadcode/location"
require_relative "deadcode/definition"
require_relative "deadcode/reference"
require_relative "deadcode/send"
require_relative "deadcode/plugins"
require_relative "deadcode/remover"

module Spoom
  module Deadcode
    class Error < Spoom::Error
      extend T::Helpers

      abstract!
    end

    class ParserError < Error; end

    class IndexerError < Error
      extend T::Sig

      sig { params(message: String, parent: Exception).void }
      def initialize(message, parent:)
        super(message)
        set_backtrace(parent.backtrace)
      end
    end

    class << self
      extend T::Sig

      sig { params(ruby: String, file: String).returns(Prism::Node) }
      def parse_ruby(ruby, file:)
        result = Prism.parse(ruby)
        unless result.success?
          message = result.errors.map do |e|
            "#{e.message} (at #{e.location.start_line}:#{e.location.start_column})."
          end.join(" ")

          raise ParserError, "Error while parsing #{file}: #{message}"
        end

        result.value
      end

      sig do
        params(
          index: Index,
          node: Prism::Node,
          ruby: String,
          file: String,
          plugins: T::Array[Deadcode::Plugins::Base],
        ).void
      end
      def index_node(index, node, ruby, file:, plugins: [])
        visitor = Spoom::Deadcode::Indexer.new(file, ruby, index, plugins: plugins)
        visitor.visit(node)
      rescue => e
        raise IndexerError.new("Error while indexing #{file} (#{e.message})", parent: e)
      end

      sig { params(index: Index, ruby: String, file: String, plugins: T::Array[Deadcode::Plugins::Base]).void }
      def index_ruby(index, ruby, file:, plugins: [])
        node = parse_ruby(ruby, file: file)
        index_node(index, node, ruby, file: file, plugins: plugins)
      end

      sig { params(index: Index, erb: String, file: String, plugins: T::Array[Deadcode::Plugins::Base]).void }
      def index_erb(index, erb, file:, plugins: [])
        ruby = ERB.new(erb).src
        index_ruby(index, ruby, file: file, plugins: plugins)
      end
    end
  end
end
