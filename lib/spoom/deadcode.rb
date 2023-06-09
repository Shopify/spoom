# typed: strict
# frozen_string_literal: true

require "erubi"
require "syntax_tree"

require_relative "deadcode/erb"
require_relative "deadcode/index"
require_relative "deadcode/indexer"

require_relative "deadcode/location"
require_relative "deadcode/definition"
require_relative "deadcode/reference"
require_relative "deadcode/send"

module Spoom
  module Deadcode
    class Error < Spoom::Error
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { params(message: String, parent: Exception).void }
      def initialize(message, parent:)
        super(message)
        set_backtrace(parent.backtrace)
      end
    end

    class ParserError < Error; end
    class IndexerError < Error; end

    class << self
      extend T::Sig

      sig { params(index: Index, ruby: String, file: String).void }
      def index_ruby(index, ruby, file:)
        node = SyntaxTree.parse(ruby)
        visitor = Spoom::Deadcode::Indexer.new(file, ruby, index)
        visitor.visit(node)
      rescue SyntaxTree::Parser::ParseError => e
        raise ParserError.new("Error while parsing #{file} (#{e.message} at #{e.lineno}:#{e.column})", parent: e)
      rescue => e
        raise IndexerError.new("Error while indexing #{file} (#{e.message})", parent: e)
      end

      sig { params(index: Index, erb: String, file: String).void }
      def index_erb(index, erb, file:)
        ruby = ERB.new(erb).src
        index_ruby(index, ruby, file: file)
      end
    end
  end
end
