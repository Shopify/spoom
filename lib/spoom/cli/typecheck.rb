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
      def typecheck(*paths)
        files = files_to_typecheck(paths)

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
          class Binding; end
          class Bundler; end
          class CGI; end
          class Comparable; end
          class Complex; end
          class Date; end
          class Dir; end
          class ERB; end
          class Encoding; end
          class Errno; end
          class Exception; end
          class FalseClass; end
          class Float < Numeric; end
          class Hash; end
          class IO; end
          class IRB; end
          class Integer < Nmeric; end
          class Logger; end
          class NoMethodError < StandardError; end
          class NameError < StandardError; end
          class NilClass; end
          class Numeric; end
          class ObjectSpace; end
          class Open3; end
          class Pathname; end
          class Proc; end
          class Process; end
          class Range; end
          class Rational < Numeric; end
          class Regexp; end
          class Set; end
          class StandardError; end
          class String; end
          class StringIO; end
          class Symbol; end
          class Time; end
          class TrueClass; end
          class UnboundMethod; end

          module T
            class Array; end
            class Hash; end
          end

          RBS = nil
          ENV = nil
          ARGV = nil
          REXML = nil
          Racc = nil
          RDoc = nil
          RUBY_VERSION = nil
        RBI

        $stderr.puts "Parsing payload..."
        namer = Spoom::Typecheck::Namer.new(model, "<payload>")
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        namer.visit(Spoom.parse_ruby(payload, file: "<payload>"))
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        # Equivalent to parser - 2000 phase in Sorbet
        $stderr.puts "Parsing #{files.size} files..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        parsed_files = files.map do |file|
          content = File.read(file)
          node = Spoom.parse_ruby(content, file: file)
          [file, node]
        rescue Spoom::ParseError => e
          puts "Error parsing #{file}: #{e.message}"
          nil
        end.compact
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        # TODO: desugar?
        # TODO: rewrite?

        # $stderr.puts "Empty..."
        # parsed_files.each do |file, node|
        #   model_builder = Spoom::Typecheck::Empty.new
        #   model_builder.visit(node)
        # end
        # ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        # $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        # $stderr.puts "Namespaces..."
        # parsed_files.each do |file, node|
        #   model_builder = Spoom::Model::NamespaceVisitor.new
        #   model_builder.visit(node)
        # end
        # ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        # $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        # Equivalent to namer - 4000 phase in Sorbet
        $stderr.puts "Namer..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        parsed_files.each do |file, node|
          namer = Spoom::Typecheck::Namer.new(model, file)
          namer.visit(node)
        end
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        # TODO: stop after, print tree
        # print_trees(parsed_files)

        # exit(1)

        # Equivalent to resolver - 5000 phase in Sorbet
        $stderr.puts "Resolver..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        parsed_files.each do |file, node|
          resolver = Spoom::Typecheck::Resolver.new(model, file)
          resolver.visit(node)

          resolver.errors.each do |error|
            $stderr.puts "#{red("Error")}: #{error.message}"
            $stderr.puts error.location.snippet
          end
        end
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        exit(1)

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

        # TODO: stop after, print tree

        # Finalize model ancestry graph
        # Equivalent to resolver/GlobalPass in Sorbet
        $stderr.puts "GlobalPass..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        model.finalize!
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        # Equivalent to infer - 7000 phase in Sorbet
        $stderr.puts "Infer..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        cfgs.each do |method, (node, cfg)|
          # puts "## Infer: " + method.full_name
          infer = Spoom::Typecheck::Infer.new(model, method, node, cfg)
          infer.infer
        end
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        # TODO: stop after, print tree
        # print_trees(parsed_files)
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
