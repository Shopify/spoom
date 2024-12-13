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

          say("Translating signatures from `#{from}` to `#{to}` " \
            "in `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          translated_files = T.let(0, Integer)

          files.each do |file|
            contents = File.read(file)

            if contents.lines.first&.start_with?("# encoding:")
              encoding = T.must(contents.lines.first).gsub(/^#\s*encoding:\s*/, "").strip
              contents = contents.force_encoding(encoding)
            end

            contents = Spoom::Sorbet::TranslateSigs.rbi_to_rbs(contents)
            File.write(file, contents)
            translated_files += 1
          rescue RBI::Error => error
            say_warning("Can't parse #{file}: #{error.message}")
            next
          end

          say("Translated signatures in `#{translated_files}` file#{translated_files == 1 ? "" : "s"}.")
        end
      end
    end
  end
end
