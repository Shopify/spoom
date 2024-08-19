# typed: true
# frozen_string_literal: true

require_relative "../deadcode"

module Spoom
  module Cli
    class CFG < Thor
      extend T::Sig
      include Helper

      default_task :cfg

      desc "cfg PATH...", "Show the control flow graph of a Ruby file"
      option :compact, type: :boolean, default: true, desc: "Compact empty blocks away"
      def cfg(*paths)
        files = files_to_typecheck(paths)

        files.each do |file|
          puts "Processing #{file}..."
          result = Prism.parse(File.read(file))

          unless result.success?
            result.errors.each do |e|
              location = Location.from_prism(file, e.location)
              $stderr.puts "#{location}: #{red("error")}: #{e.message}"
            end

            next
          end

          node = result.value
          cfgs = Spoom::CFG.from_node(node)
          cfgs.compact! if options[:compact]
          cfgs.show_dot
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
      end
    end
  end
end
