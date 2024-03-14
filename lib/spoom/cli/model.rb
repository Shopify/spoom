# typed: true
# frozen_string_literal: true

require_relative "../model"

module Spoom
  module Cli
    class Model < Thor
      extend T::Sig
      include Helper

      default_task :model

      desc "model PATH...", "TMP"
      def model(*paths)
        paths << exec_path if paths.empty?
        model = build_model(paths)

        model.symbols.each do |full_name, scope|
          puts scope.full_name

          scope.defs.each do |scope_def|
            puts "  #{scope_def.location}"

            next unless scope_def.is_a?(Spoom::Model::ScopeDef)
            scope_def.constant_refs.uniq(&:to_s).each do |ref|
              puts "    #{ref}"
            end
          end
        end
      end

      desc "file-refs PATH", "TMP"
      def file_refs(path = exec_path)
        model = build_model(path)

        file_refs = T.let({}, T::Hash[String, T::Set[String]])

        model.symbols.each do |full_name, symbol|
          next if symbol.is_a?(Spoom::Model::ConstantDef)
          next if symbol.defs.size > 1

          symbol.defs.each do |scope_def|
            next unless scope_def.is_a?(Spoom::Model::ScopeDef)
            from_file = scope_def.location.file

            to_set = file_refs[from_file] ||= Set.new
            scope_def.constant_refs.each do |ref|
              next unless ref.resolved?
              next if T.must(ref.target).defs.size > 1

              T.must(ref.target).defs.each do |defn|
                to_file = defn.location.file
                next if from_file == to_file

                puts "#{from_file} -> #{to_file}"
                to_set << to_file
              end
            end
          end
        end

        dot = String.new
        dot << "digraph G {\n"
        file_refs.each do |file, refs|
          refs.each do |ref|
            dot << "\"#{file}\" -> \"#{ref}\""
          end
        end
        dot << "}\n"

        context = Context.new(".")
        context.write!("graph.dot", dot)

        res = context.exec("dot -Tpng graph.dot -o graph.png")
        raise "Error: #{res.err}" unless res.status

        context.exec("open -W -F graph.png")
        context.remove!("graph.dot")
      end

      no_commands do
        def build_model(path)
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
          files = Dir.glob(File.join(path, "**/*.rb")).sort

          $stderr.puts "Building model..."
          model = Spoom::Model.new

          total = files.size
          files.each_with_index do |file, i|
            $stderr.print "#{i}/#{total}\r"
            next if file.match?(/test|spec|vendor|tmp/)

            builder = Spoom::Model::Builder.new(model, file)
            builder.enter_visit
          rescue Spoom::ParseError => e
            say_error("Error parsing #{file}: #{e.message}")
            next
          end

          $stderr.puts "Finalizing model..."
          model.finalize
          model
        end
      end
    end
  end
end
