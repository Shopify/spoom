# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    # Equivalent to parser - 2000 phase in Sorbet
    class Parse
      class Result < T::Struct
        prop :errors, T::Array[Error], default: []
        prop :parsed_files, T::Array[[String, Prism::Node]], default: []
      end

      class << self
        extend T::Sig

        sig { params(files: T::Array[String]).returns(Result) }
        def run(files)
          result = Result.new

          files.each do |file|
            content = File.read(file)
            res = Prism.parse(content)
            res.errors.each do |e|
              result.errors << Error.new(e.message, Location.from_prism(file, e.location))
            end
            result.parsed_files << [file, res.value]
          end

          result
        end

        private

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
