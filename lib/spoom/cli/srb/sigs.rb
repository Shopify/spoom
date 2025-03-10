# typed: true
# frozen_string_literal: true

require "spoom/sorbet/sigs"

module Spoom
  module Cli
    module Srb
      class Sigs < Thor
        include Helper

        desc "translate", "Translate signatures from/to RBI and RBS"
        option :from, type: :string, aliases: :f, desc: "From format", enum: ["rbi", "rbs"], default: "rbi"
        option :to, type: :string, aliases: :t, desc: "To format", enum: ["rbi", "rbs"], default: "rbs"
        def translate(*paths)
          from = options[:from]
          to = options[:to]

          if from == to
            say_error("Can't translate signatures from `#{from}` to `#{to}`")
            exit(1)
          end

          files = collect_files(paths)

          say("Translating signatures from `#{from}` to `#{to}` " \
            "in `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          case from
          when "rbi"
            transformed_files = transform_files(files) do |_file, contents|
              Spoom::Sorbet::Sigs.rbi_to_rbs(contents)
            end
          when "rbs"
            transformed_files = transform_files(files) do |_file, contents|
              Spoom::Sorbet::Sigs.rbs_to_rbi(contents)
            end
          end

          say("Translated signatures in `#{transformed_files}` file#{transformed_files == 1 ? "" : "s"}.")
        end

        desc "strip", "Strip all the signatures from the files"
        def strip(*paths)
          files = collect_files(paths)

          say("Stripping signatures from `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          transformed_files = transform_files(files) do |_file, contents|
            Spoom::Sorbet::Sigs.strip(contents)
          end

          say("Stripped signatures from `#{transformed_files}` file#{transformed_files == 1 ? "" : "s"}.")
        end

        no_commands do
          def transform_files(files, &block)
            transformed_count = 0

            files.each do |file|
              contents = File.read(file)
              first_line = contents.lines.first

              if first_line&.start_with?("# encoding:")
                encoding = T.must(first_line).gsub(/^#\s*encoding:\s*/, "").strip
                contents = contents.force_encoding(encoding)
              end

              contents = block.call(file, contents)
              File.write(file, contents)
              transformed_count += 1
            rescue RBI::Error => error
              say_warning("Can't parse #{file}: #{error.message}")
              next
            end

            transformed_count
          end
        end
      end
    end
  end
end
