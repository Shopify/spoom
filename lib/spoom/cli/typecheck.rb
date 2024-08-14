# typed: true
# frozen_string_literal: true

require_relative "../deadcode"

module Spoom
  module Cli
    class Typecheck < Thor
      extend T::Sig
      include Helper

      default_task :typecheck

      desc "typecheck PATH...", "Render snippet"
      option :payload, type: :boolean, default: true, desc: "Include payload"
      option :stop_after,
        enum: ["files", "payload", "parser", "namer", "resolver", "cfg", "global_pass", "infer"],
        desc: "Stop after a specific phase"
      option :print,
        enum: ["files", "parser-tree", "parser-prism", "namer-tree", "resolver-tree", "infer-tree"],
        desc: "Print things"
      option :focus, type: :string, desc: "Focus on a specific file"
      def typecheck(*paths)
        tc_starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        files = files_to_typecheck(paths)

        if options[:print] == "files"
          files.each do |file|
            puts file
          end
        end
        exit(1) if options[:stop_after] == "files"

        errors = 0
        model = Spoom::Model.new

        # Payload
        payload = <<~RBI
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

          RBS = nil
          ENV = nil
          ARGV = nil
          REXML = nil
          Racc = nil
          RDoc = nil
          RUBY_VERSION = nil
        RBI

        if options[:payload]
          $stderr.puts "Parsing payload..."
          starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          namer = Spoom::Typecheck::Namer.new(model, "<payload>")
          namer.visit(Spoom.parse_ruby(payload, file: "<payload>"))
          ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          $stderr.puts "  took #{(ending - starting).round(2)} seconds"
        end
        exit(1) if options[:stop_after] == "payload"

        # Equivalent to parser - 2000 phase in Sorbet
        $stderr.puts "Parsing #{files.size} files..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        parsed_files = files.map do |file|
          content = File.read(file)
          node = Spoom.parse_ruby(content, file: file)
          [file, node]
        rescue Spoom::ParseError => e
          puts "Error parsing #{file}: #{e.message}"
          errors += 1
          nil
        end.compact
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        if options[:print] == "parser-tree"
          print_trees(parsed_files)
        elsif options[:print] == "parser-prism"
          parsed_files.each do |file, node|
            puts file
            puts node.inspect
          end
        end
        exit(1) if options[:stop_after] == "parser"

        # TODO: desugar?
        # TODO: rewrite?

        # Equivalent to namer - 4000 phase in Sorbet
        $stderr.puts "Namer..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        parsed_files.each do |file, node|
          namer = Spoom::Typecheck::Namer.new(model, file)
          namer.visit(node)
          namer.errors.each do |error|
            next if options[:focus] && error.location.file != options[:focus]

            $stderr.puts "#{red("Error")}: #{error.message}"
            $stderr.puts error.location.snippet
            errors += 1
          end
        end
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        if options[:print] == "namer-tree"
          print_trees(parsed_files)
        end
        exit(1) if options[:stop_after] == "namer"

        # Equivalent to resolver - 5000 phase in Sorbet
        $stderr.puts "Resolver..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        parsed_files.each do |file, node|
          resolver = Spoom::Typecheck::Resolver.new(model, file)
          resolver.visit(node)

          resolver.errors.each do |error|
            next if options[:focus] && error.location.file != options[:focus]

            $stderr.puts "#{red("Error")}: #{error.message}"
            $stderr.puts error.location.snippet
            errors += 1
          end
        end
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        if options[:print] == "resolver-tree"
          print_trees(parsed_files)
        end
        exit(1) if options[:stop_after] == "resolver"

        # TODO: stop after, print tree
        # print_trees(parsed_files)

        # Equivalent to CFG - 6000 phase in Sorbet
        $stderr.puts "CFG..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        cfgs = T.let({}, T::Hash[Model::Method, [Prism::Node, Spoom::CFG]])
        parsed_files.each do |file, node|
          resolver = Spoom::Typecheck::CFG.new(model, file)
          resolver.visit(node)
          cfgs.merge!(resolver.cfgs)
        end
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"
        exit(1) if options[:stop_after] == "cfg"

        # TODO: stop after, print tree

        # Finalize model ancestry graph
        # Equivalent to resolver/GlobalPass in Sorbet
        $stderr.puts "GlobalPass..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        model.finalize!
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"
        exit(1) if options[:stop_after] == "global_pass"

        # Equivalent to infer - 7000 phase in Sorbet
        $stderr.puts "Infer..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        cfgs.each do |method, (node, cfg)|
          # puts "## Infer: " + method.full_name
          # if method.full_name == "RBI::NodeWithComments::annotations"
          #   cfg.show_dot
          # end
          infer = Spoom::Typecheck::Infer.new(model, method, node, cfg)
          infer.infer

          infer.errors.each do |error|
            next if options[:focus] && error.location.file != options[:focus]

            $stderr.puts "#{red("Error")}: #{error.message}"
            $stderr.puts error.location.snippet
            errors += 1
          end
        end
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"
        exit(1) if options[:stop_after] == "infer"

        # TODO: stop after, print tree
        # print_trees(parsed_files)
        tc_ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        if errors > 0
          $stderr.puts "Found #{errors} errors in #{(tc_ending - tc_starting).round(2)} seconds"
          exit(1)
        else
          $stderr.puts "Found no errors in #{(tc_ending - tc_starting).round(2)} seconds"
          exit(0)
        end
      end

      private

      no_commands do
        sig { params(paths: T::Array[String]).returns(T::Array[String]) }
        def files_to_typecheck(paths)
          paths << "." if paths.empty?

          paths.flat_map do |path|
            if File.file?(path)
              [path]
            elsif File.directory?(path)
              Dir.glob("#{path}/**/*.{rb,rbi}")
            else
              Dir.glob(path)
            end
          end
        end

        sig { params(files: T::Array[[String, Prism::Node]]).void }
        def print_trees(files)
          files.each do |file, node|
            puts file
            printer = Spoom::Typecheck::Printer.new
            printer.visit(node)
          end
        end
      end
    end
  end
end
