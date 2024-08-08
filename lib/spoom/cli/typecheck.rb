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

        files = time do
          $stderr.puts "Listing files..."
          files_to_typecheck(paths)
        end

        if options[:print] == "files"
          files.each do |file|
            puts file
          end
        end
        exit(1) if options[:stop_after] == "files"

        errors = 0
        model = Spoom::Model.new

        if options[:payload]
          time do
            $stderr.puts "Parsing payload..."
            namer = Spoom::Typecheck::Namer.new(model, "<payload>")
            namer.visit(Spoom.parse_ruby(Spoom::Typecheck::PAYLOAD, file: "<payload>"))
          end
        end
        exit(1) if options[:stop_after] == "payload"

        # Equivalent to parser - 2000 phase in Sorbet
        result = time do
          $stderr.puts "Parsing..."
          Spoom::Typecheck::Parse.run(files)
        end
        parsed_files = result.parsed_files
        errors += result.errors.size
        print_errors(result.errors, focus: options[:focus])

        if options[:print] == "parser-tree"
          print_trees(parsed_files)
        elsif options[:print] == "parser-prism"
          parsed_files.each do |file, node|
            puts file
            # puts node.inspect
          end
        end
        exit(1) if options[:stop_after] == "parser"

        # TODO: desugar?
        # TODO: rewrite?

        # Equivalent to namer - 4000 phase in Sorbet
        result = time do
          $stderr.puts "Namer..."
          Spoom::Typecheck::Namer.run(model, parsed_files)
        end
        errors += result.errors.size
        print_errors(result.errors, focus: options[:focus])

        if options[:print] == "namer-tree"
          print_trees(parsed_files)
        end
        exit(1) if options[:stop_after] == "namer"

        # Equivalent to resolver - 5000 phase in Sorbet
        result = time do
          $stderr.puts "Resolver..."
          Spoom::Typecheck::Resolver.run(model, parsed_files)
        end

        result.errors.each do |error|
          next if options[:focus] && error.location.file != options[:focus]

          $stderr.puts "#{error.location}: #{red("Error")}: #{error.message}"
          # $stderr.puts error.location.snippet
          errors += 1
        end

        if options[:print] == "resolver-tree"
          print_trees(parsed_files)
        end
        exit(1) if options[:stop_after] == "resolver"

        # Equivalent to CFG - 6000 phase in Sorbet
        $stderr.puts "CFG..."
        starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = Spoom::Typecheck::CFG.run(model, parsed_files)
        errors += result.errors.size
        print_errors(result.errors, focus: options[:focus])
        result.cfgs.each do |method_cfg|
          # next unless method_cfg.symbol_def.name == "source"

          # puts method_cfg.symbol_def.symbol
          # puts method_cfg.cfg.to_dot
          method_cfg.cfg.show_dot
          # exit
        end
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        $stderr.puts "  took #{(ending - starting).round(2)} seconds"

        exit(1) if options[:stop_after] == "cfg"

        # Finalize model ancestry graph
        # Equivalent to resolver/GlobalPass in Sorbet
        time do
          $stderr.puts "GlobalPass..."
          model.finalize!
        end
        exit(1) if options[:stop_after] == "global_pass"

        # Equivalent to infer - 7000 phase in Sorbet
        result = time do
          $stderr.puts "Infer..."
          Spoom::Typecheck::Infer.run(model, result.cfgs)
        end
        errors += result.errors.size
        print_errors(result.errors, focus: options[:focus])
        exit(1) if options[:stop_after] == "infer"

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
        sig { type_parameters(:R).params(block: T.proc.returns(T.type_parameter(:R))).returns(T.type_parameter(:R)) }
        def time(&block)
          starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          res = yield
          ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          duration = (ending - starting)
          duration = if duration > 60
            "#{(duration / 60).round(2)} minutes"
          else
            "#{duration.round(2)} seconds"
          end

          $stderr.puts "  took #{duration}" if options[:timers]
          res
        end

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

        sig { params(errors: T::Array[Spoom::Typecheck::Error], focus: T.nilable(String)).void }
        def print_errors(errors, focus: nil)
          errors.each do |error|
            next if options[:focus] && error.location.file != options[:focus]

            $stderr.puts "#{error.location}: #{red("Error")}: #{error.message}"
            # $stderr.puts error.location.snippet
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

# Interesting points

## parsing:
# do we keep the original AST?
#   memory concerns
#   complexity of creating our own AST
#   desugar
#   incorpoare CFG?
## namer:
# find all the things that can be symbols and replace them by a placeholder
# honestly could be in resolve already
## resolver:
# make all the names resolved symbols
## infer:
# compute the types of all the nodes
# needs global pass to resolve all the symbols
