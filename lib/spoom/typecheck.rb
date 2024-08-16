# typed: strict
# frozen_string_literal: true

require "rbi"
require "ext/prism"
require "ext/rbi"

module Spoom
  module Typecheck
    class Error < Spoom::Error
      extend T::Sig

      sig { returns(Location) }
      attr_reader :location

      sig { params(message: String, location: Location).void }
      def initialize(message, location)
        super(message)

        @location = location
      end
    end
  end
end

require "spoom/typecheck/printer"
require "spoom/typecheck/empty" # TODO

require "spoom/typecheck/parse"
require "spoom/typecheck/namer"
require "spoom/typecheck/resolver"
require "spoom/typecheck/cfg"
require "spoom/typecheck/infer"

module Spoom
  module Typecheck
    extend T::Sig

    PAYLOAD = <<~RBI
      module Kernel
        def require; end
        def extend; end
      end

      class BasicObject
      end

      class Object < BasicObject
        include Kernel
      end

      class Module
        def extend; end
        def include; end

        include T::Sig
        include T::Helpers
        include T::Generics
      end

      class Class < Module
        sig { returns(T.attached_class) }
        def new; end

        def is_a?(klass); end
      end

      module T
        module Sig
          def sig; end
        end

        module Helpers
          def abstract!; end
          def interface!; end
        end

        module Generics
          def type_member; end
          def type_template; end
          def has_attached_class!; end
        end

        class Array; end
        class Hash; end

        class << self
          def let; end
          def cast; end
          def unsafe; end
          def nilable; end
        end
      end

      class Sorbet
      end
    RBI

    PAYLOAD_STDLIB = <<~RBI
      module Kernel
        def require; end
      end

      class BasicObject
      end

      class Object < BasicObject
        include Kernel
      end

      class Module
        def extend; end
        def include; end
      end

      class Class < Module
        sig { returns(T.attached_class) }
        def new; end
      end

      class ArgumentError < StandardError; end
      class Array; end
      class Benchmark; end
      class Binding; end
      class Bundler; end
      class CGI; end
      class Comparable; end
      class Complex; end
      class Date; end
      class Dir; end
      class Digest; end
      class ERB; end
      class Encoding; end
      class Errno; end
      class Etc; end
      class Exception; end
      class FalseClass; end
      class Float < Numeric; end
      class Hash; end
      class IO; end
      class IRB; end
      class Integer < Nmeric; end
      class Logger; end
      class MalformattedArgumentError < ArgumentError; end
      class Marshal; end
      class NoMethodError < StandardError; end
      class NameError < StandardError; end
      class Net; end
      class NilClass; end
      class Numeric; end
      class ObjectSpace; end
      class Open3; end
      class OpenSSL; end
      class Pathname; end
      class Proc; end
      class Process; end
      class Range; end
      class RangeError < StandardError; end
      class Rational < Numeric; end
      class RbConfig; end
      class Regexp; end
      class RubyVM; end
      class RuntimeError < StandardError; end
      class ScriptError < Exception; end
      class Set; end
      class SocketError < StandardError; end
      class StandardError; end
      class String; end
      class StringIO; end
      class Symbol; end
      class SyntaxError < StandardError; end
      class Tempfile; end
      class Time; end
      class TracePoint; end
      class TrueClass; end
      class TypeError < StandardError; end
      class UnboundMethod; end
      class WEBrick; end
      class YAML; end

      module T
        class Array; end
        class Hash; end

        class << self
          def let; end
          def cast; end
        end
        def self.unsafe; end
      end

      class Sorbet; end

      RBS = nil
      ENV = nil
      ARGV = nil
      REXML = nil
      Racc = nil
      RDoc = nil
      RUBY_VERSION = nil
    RBI

    class Result < T::Struct
      prop :model, Spoom::Model, default: Spoom::Model.new
      prop :parsed_files, T::Array[[String, Prism::Node]], default: []
      prop :errors, T::Array[Error], default: []
    end

    class << self
      extend T::Sig

      sig do
        params(
          files: T::Array[String],
          payload: T.nilable(String),
          stop_after: T.nilable(String),
        ).returns(Typecheck::Result)
      end
      def run(files, payload: PAYLOAD, stop_after: nil)
        result = Typecheck::Result.new

        return result if stop_after == "files"

        if payload
          namer = Spoom::Typecheck::Namer.new(result.model, "<payload>")
          namer.visit(Spoom.parse_ruby(payload, file: "<payload>"))
        end
        return result if stop_after == "payload"

        # Equivalent to parser - 2000 phase in Sorbet
        parse = Spoom::Typecheck::Parse.run(files)
        result.errors.concat(parse.errors)
        result.parsed_files = parse.parsed_files

        return result if stop_after == "parser"

        # TODO: desugar?
        # TODO: rewrite?

        # Equivalent to resolver - 4000 phase in Sorbet
        namer = Spoom::Typecheck::Namer.run(result.model, result.parsed_files)
        result.errors.concat(namer.errors)
        return result if stop_after == "namer"

        # Equivalent to resolver - 5000 phase in Sorbet
        resolver = Spoom::Typecheck::Resolver.run(result.model, result.parsed_files)
        result.errors.concat(resolver.errors)
        return result if stop_after == "resolver"

        # Equivalent to CFG - 6000 phase in Sorbet
        # cfg = Spoom::Typecheck::CFG.run(result.model, result.parsed_files)
        # result.errors.concat(cfg.errors)
        # return result if stop_after == "cfg"

        # Finalize model ancestry graph
        # Equivalent to resolver/GlobalPass in Sorbet
        result.model.finalize!
        return result if stop_after == "global_pass"

        # Equivalent to infer - 7000 phase in Sorbet
        infer = Spoom::Typecheck::Infer.run(result.model, result.parsed_files)
        result.errors.concat(infer.errors)
        return result if stop_after == "infer"

        result
      end

      sig do
        params(
          files: T::Array[String],
          snippet: Spoom::Snippet,
          payload: T.nilable(String),
          stop_after: T.nilable(String),
        ).returns(Typecheck::Result)
      end
      def run_snippet(files, snippet, payload: PAYLOAD, stop_after: nil)
        files = [*files, snippet.file]
        run(files, payload: payload, stop_after: stop_after)
      end
    end
  end
end
