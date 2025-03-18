# typed: true
# frozen_string_literal: true

module Spoom
  module Cli
    module Srb
      class Assertions < Thor
        extend T::Sig
        include Helper

        desc "translate", "Translate type assertions from/to RBI and RBS"
        option :from, type: :string, aliases: :f, desc: "From format", enum: ["rbi"], default: "rbi"
        option :to, type: :string, aliases: :t, desc: "To format", enum: ["rbs"], default: "rbs"
        option :let, type: :boolean, desc: "Translate `T.let` to `nil #: String?`", default: true
        option :cast, type: :boolean, desc: "Translate `T.cast` to `# as String`", default: true
        option :must, type: :boolean, desc: "Translate `T.must` to `# as not nil`", default: true
        def translate(*paths)
          from = options[:from]
          to = options[:to]
          files = collect_files(paths)

          say("Translating type assertions from `#{from}` to `#{to}` " \
            "in `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          transformed_files = transform_files(files) do |file, contents|
            Spoom::Sorbet::Assertions.rbi_to_rbs(
              contents,
              file: file,
              let: options[:let],
              cast: options[:cast],
              must: options[:must],
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
