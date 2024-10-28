# typed: true
# frozen_string_literal: true

require "spoom/sorbet/translate_sigs"

module Spoom
  module Cli
    module Srb
      class Sigs < Thor
        include Helper

        desc "translate", "Translate signatures from/to RBI and RBS"
        option :from, type: :string, aliases: :f, desc: "From format", enum: ["rbi"], default: "rbi"
        option :to, type: :string, aliases: :t, desc: "To format", enum: ["rbs"], default: "rbs"
        def translate(*paths)
          from = options[:from]
          to = options[:to]
          paths << "." if paths.empty?

          files = paths.flat_map do |path|
            if File.file?(path)
              [path]
            else
              Dir.glob("#{path}/**/*.rb")
            end
          end

          if files.empty?
            say_error("No files to translate")
            exit(1)
          end

          say("Translating signatures from `#{from}` to `#{to}` in `#{files.size}` files...\n\n")

          files.each do |file|
            contents = File.read(file)
            contents = Spoom::Sorbet::TranslateSigs.rbi_to_rbs(contents)
            File.write(file, contents)
          rescue RBI::ParseError => error
            say_warning("Can't parse #{file}: #{error.message}")
            next
          end

          say("Translated signatures in `#{files.size}` files.")
        end
      end
    end
  end
end
