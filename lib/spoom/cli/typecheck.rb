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
        RBI

        model_builder = Spoom::Model::Builder.new(model, "<payload>")
        model_builder.visit(Spoom.parse_ruby(payload, file: "<payload>"))

        parsed_files = files.map do |file|
          content = File.read(file)
          node = Spoom.parse_ruby(content, file: file)
          model_builder = Spoom::Model::Builder.new(model, file)
          model_builder.visit(node)
          [file, node]
        rescue Spoom::ParseError => e
          puts "Error parsing #{file}: #{e.message}"
          nil
        end.compact

        model.finalize!

        # ast = Spoom::AST.from_prism(node, file: "-")
        # puts ast.inspect

        # desugar = Spoom::Desugar.new
        # desugar.visit(node)
        # puts node.inspect

        # puts node.inspect
        # infer = Spoom::Infer.infer(node)
        parsed_files.each do |file, node|
          puts "resolve #{file}"
          resolver = Spoom::Resolver.new(model, file)
          resolver.visit(node)
        end

        puts files
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
      end
    end
  end
end
