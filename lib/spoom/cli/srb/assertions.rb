# typed: true
# frozen_string_literal: true

module Spoom
  module Cli
    module Srb
      class Assertions < Thor
        include Helper

        desc "translate", "Translate type assertions from/to RBI and RBS"
        option :from, type: :string, aliases: :f, desc: "From format", enum: ["rbi"], default: "rbi"
        option :to, type: :string, aliases: :t, desc: "To format", enum: ["rbs"], default: "rbs"
        option :translate_t_let, type: :boolean, aliases: :t_let, desc: "Translate `T.let`", default: true
        option :translate_t_cast, type: :boolean, aliases: :t_cast, desc: "Translate `T.cast`", default: true
        option :translate_t_bind, type: :boolean, aliases: :t_bind, desc: "Translate `T.bind`", default: true
        option :translate_t_must, type: :boolean, aliases: :t_must, desc: "Translate `T.must`", default: true
        option :translate_t_unsafe, type: :boolean, aliases: :t_unsafe, desc: "Translate `T.unsafe`", default: true
        def translate(*paths)
          from = options[:from]
          to = options[:to]
          files = collect_files(paths)

          say("Translating type assertions from `#{from}` to `#{to}` " \
            "in `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          transformed_files = transform_files(files) do |file, contents|
            Spoom::Sorbet::Translate.sorbet_assertions_to_rbs_comments(
              contents,
              file: file,
              translate_t_let: options[:translate_t_let],
              translate_t_cast: options[:translate_t_cast],
              translate_t_bind: options[:translate_t_bind],
              translate_t_must: options[:translate_t_must],
              translate_t_unsafe: options[:translate_t_unsafe],
            )
          end

          say("Translated type assertions in `#{transformed_files}` file#{transformed_files == 1 ? "" : "s"}.")
        end

        no_commands do
          def transform_files(files, &block)
            transformed_count = 0

            files.each do |file|
              contents = File.read(file)
              contents = block.call(file, contents)
              File.write(file, contents)
              transformed_count += 1
            rescue Spoom::ParseError => error
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
