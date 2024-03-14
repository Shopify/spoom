# typed: true
# frozen_string_literal: true

require_relative "../model"

module Spoom
  module Cli
    class Model < Thor
      extend T::Sig
      include Helper

      default_task :model

      desc "model PATH", "TMP"
      def model(*path)
        # paths << exec_path if paths.empty?
        model = build_model(path)

        model.symbols.each do |_full_name, symbol|
          case symbol
          when Spoom::Model::UnresolvedSymbol
            puts symbol.full_name
          end
          # when Spoom::Model::Class
            # print(scope.full_name)
            # if scope.superclass_name
            #   print(" < #{scope.superclass_name}")
            # end
            # puts
          # when Spoom::Model::Module
            # puts scope.full_name
          # when Spoom::Model::Constant
            # puts scope.full_name
          # when Spoom::Model::Method
            # puts scope.full_name
          # when Spoom::Model::Accessor
            # puts scope.full_name
          # end

          # scope.definitions.each do |scope_def|
          #   puts "  #{scope_def.location}"

          #   # next unless scope_def.is_a?(Spoom::Model::ScopeDef)

          #   # scope_def.constant_refs.uniq(&:to_s).each do |ref|
          #   #   puts "    #{ref}"
          #   # end
          # end
        end

        # model.poset.show_dot(transitive: false)
      end

      desc "metrics PATH", "TMP"
      def metrics(path)
        model = build_model(path)

        counter = Spoom::Counter.new

        model.symbols.each do |_full_name, scope|
          counter.inc(T.must(scope.class.name))
        end

        counter.print
      end

      no_commands do
        sig { params(paths: T::Array[String]).returns(Spoom::Model) }
        def build_model(paths)
          $stderr.puts "Collecting files..."
          # collector = FileCollector.new(
          #   allow_extensions: [".rb"],
          #   exclude_patterns: [
          #     "test",
          #     "spec",
          #     "vendor",
          #     "tmp",
          #   ].map { |p| Pathname.new(File.join(path, p, "**")).cleanpath.to_s }
          # )
          # collector.visit_path(path)
          # files = collector.files.sort
          files = paths.flat_map do |path|
            if File.directory?(path)
              Dir.glob(File.join(path, "**/*.rb")).sort
            else
              path
            end
          end

          $stderr.puts "Building model..."
          model = Spoom::Model.new

          total = files.size
          files.each_with_index do |file, i|
            $stderr.print("#{i}/#{total}\r")
            next if file.match?(/test|spec|vendor|tmp/)

            builder = Spoom::Model::Builder.new(model, file)
            node = Spoom.parse_file(file)
            builder.visit(node)
          rescue Spoom::ParseError => e
            say_error("Error parsing #{file}: #{e.message}")
            next
          end

          $stderr.puts "Finalizing model..."
          model.finalize

          puts "Model contains #{model.symbols.size} symbols."

          model
        end
      end
    end
  end
end
