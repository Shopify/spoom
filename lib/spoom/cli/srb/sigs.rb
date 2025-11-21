# typed: true
# frozen_string_literal: true

require "spoom/bundler_helper"

module Spoom
  module Cli
    module Srb
      class Sigs < Thor
        include Helper

        desc "translate", "Translate signatures from/to RBI and RBS"
        option :from, type: :string, aliases: :f, desc: "From format", enum: ["rbi", "rbs"], default: "rbi"
        option :to, type: :string, aliases: :t, desc: "To format", enum: ["rbi", "rbs"], default: "rbs"
        option :positional_names,
          type: :boolean,
          aliases: :p,
          desc: "Use positional names when translating from RBI to RBS",
          default: true
        option :include_rbi_files, type: :boolean, desc: "Include RBI files", default: false
        option :max_line_length, type: :numeric, desc: "Max line length (pass 0 to disable)", default: 120
        option :translate_generics, type: :boolean, desc: "Translate generics", default: false
        option :translate_helpers, type: :boolean, desc: "Translate helpers", default: false
        option :translate_abstract_methods, type: :boolean, desc: "Translate abstract methods", default: false
        def translate(*paths)
          from = options[:from]
          to = options[:to]
          max_line_length = options[:max_line_length]

          if from == to
            say_error("Can't translate signatures from `#{from}` to `#{to}`")
            exit(1)
          end

          if max_line_length.nil? || max_line_length.zero?
            max_line_length = nil
          elsif max_line_length.negative?
            say_error("--max-line-length can't be negative")
            exit(1)
          else
            max_line_length = max_line_length.to_i
          end

          files = collect_files(paths, include_rbi_files: options[:include_rbi_files])

          say("Translating signatures from `#{from}` to `#{to}` " \
            "in `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          case from
          when "rbi"
            transformed_files = transform_files(files) do |file, contents|
              Spoom::Sorbet::Translate.sorbet_sigs_to_rbs_comments(
                contents,
                file: file,
                positional_names: options[:positional_names],
                max_line_length: max_line_length,
                translate_generics: options[:translate_generics],
                translate_helpers: options[:translate_helpers],
                translate_abstract_methods: options[:translate_abstract_methods],
              )
            end
          when "rbs"
            transformed_files = transform_files(files) do |file, contents|
              Spoom::Sorbet::Translate.rbs_comments_to_sorbet_sigs(
                contents,
                file: file,
                max_line_length: max_line_length,
              )
            end
          end

          say("Translated signatures in `#{transformed_files}` file#{transformed_files == 1 ? "" : "s"}.")
        end

        desc "strip", "Strip all the signatures from the files"
        def strip(*paths)
          files = collect_files(paths)

          say("Stripping signatures from `#{files.size}` file#{files.size == 1 ? "" : "s"}...\n\n")

          transformed_files = transform_files(files) do |file, contents|
            Spoom::Sorbet::Translate.strip_sorbet_sigs(contents, file: file)
          end

          say("Stripped signatures from `#{transformed_files}` file#{transformed_files == 1 ? "" : "s"}.")
        end

        # Extract signatures from gem's files and save them to the output file
        #
        # This command will use Tapioca to generate a `.rbi` file that contains the signatures of all the files listed
        # in the gemspec.
        desc "export", "Export gem files signatures"
        option :gemspec, type: :string, desc: "Path to the gemspec file", optional: true, default: nil
        option :check_sync, type: :boolean, desc: "Check the generated RBI is up to date", default: false
        def export(output_path = nil)
          gemspec = options[:gemspec]

          unless gemspec
            say("Locating gemspec file...")
            gemspec = Dir.glob("*.gemspec").first
            unless gemspec
              say_error("No gemspec file found")
              exit(1)
            end
            say("Using `#{gemspec}` as gemspec file")
          end

          spec = Gem::Specification.load(gemspec)

          # First, we copy the files to a temporary directory so we can rewrite them without messing with the
          # original ones.
          say("Copying files to a temporary directory...")
          copy_context = Spoom::Context.mktmp!
          FileUtils.cp_r(
            ["Gemfile", "Gemfile.lock", gemspec, "lib/"],
            copy_context.absolute_path,
          )

          # Then, we transform the copied files to translate all the RBS signatures into RBI signatures.
          say("Translating signatures from RBS to RBI...")
          files = collect_files([copy_context.absolute_path])
          transform_files(files) do |file, contents|
            Spoom::Sorbet::Translate.rbs_comments_to_sorbet_sigs(contents, file: file)
          end

          # We need to inject `extend T::Sig` to be sure all the classes can run the `sig{}` blocks.
          # For this we find the entry point of the gem and inject the `extend T::Sig` line at the top of the file.
          entry_point = "lib/#{spec.name}.rb"
          unless copy_context.file?(entry_point)
            say_error("No entry point found at `#{entry_point}`")
            exit(1)
          end

          say("Injecting `extend T::Sig` to `#{entry_point}`...")
          copy_context.write!(entry_point, <<~RB)
            require "sorbet-runtime"

            class Module; include T::Sig; end
            extend T::Sig

            #{copy_context.read(entry_point)}
          RB

          # Now we create a new context to import our modified gem and run tapioca
          say("Running Tapioca...")
          tapioca_context = Spoom::Context.mktmp!
          tapioca_context.write_gemfile!(<<~GEMFILE)
            source "https://rubygems.org"

            #{Spoom::BundlerHelper.gem_requirement_from_real_bundle("rbs")}
            #{Spoom::BundlerHelper.gem_requirement_from_real_bundle("tapioca")}

            gem "#{spec.name}", path: "#{copy_context.absolute_path}"
          GEMFILE
          exec(tapioca_context, "bundle install")
          exec(tapioca_context, "bundle exec tapioca gem #{spec.name} --no-doc --no-loc --no-file-header")

          rbi_path = tapioca_context.glob("sorbet/rbi/gems/#{spec.name}@*.rbi").first
          unless rbi_path && tapioca_context.file?(rbi_path)
            say_error("No RBI file found at `sorbet/rbi/gems/#{spec.name}@*.rbi`")
            exit(1)
          end

          tapioca_context.write!(rbi_path, tapioca_context.read(rbi_path).gsub(/^# typed: true/, <<~RB.rstrip))
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for types exported from the `#{spec.name}` gem.
            # Please instead update this file by running `bundle exec spoom srb sigs export`.
          RB

          output_path ||= "rbi/#{spec.name}.rbi"
          generated_path = tapioca_context.absolute_path_to(rbi_path)

          if options[:check_sync]
            # If the check option is set, we just compare the generated RBI with the one in the gem.
            # If they are different, we exit with a non-zero exit code.
            unless system("diff -u -L 'generated' -L 'current' #{generated_path} #{output_path} >&2")
              say_error(<<~ERR, status: "\nError")
                The RBI file at `#{output_path}` is not up to date

                Please run `bundle exec spoom srb sigs export` to update it.
              ERR
              exit(1)
            end

            say("The RBI file at `#{output_path}` is up to date")
            exit(0)
          else
            output_dir = File.dirname(output_path)
            FileUtils.rm_rf(output_dir)
            FileUtils.mkdir_p(output_dir)
            FileUtils.cp(generated_path, output_path)

            say("Exported signatures to `#{output_path}`")
          end
        ensure
          copy_context&.destroy!
          tapioca_context&.destroy!
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

          def exec(context, command)
            res = context.exec(command)

            unless res.status
              $stderr.puts "Error: #{command} failed"
              $stderr.puts res.err
              exit(1)
            end
          end
        end
      end
    end
  end
end
