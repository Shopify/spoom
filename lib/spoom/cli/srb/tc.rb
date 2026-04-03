# typed: true
# frozen_string_literal: true

module Spoom
  module Cli
    module Srb
      class Tc < Thor
        include Helper

        default_task :tc

        SORT_CODE = "code"
        SORT_LOC = "loc"
        SORT_ENUM = [SORT_CODE, SORT_LOC]

        DEFAULT_FORMAT = "%C - %F:%L: %M"

        desc "tc", "Run `srb tc`"
        option :limit, type: :numeric, aliases: :l, desc: "Limit displayed errors"
        option :code, type: :numeric, aliases: :c, desc: "Filter displayed errors by code"
        option :sort, type: :string, aliases: :s, desc: "Sort errors", enum: SORT_ENUM, default: SORT_LOC
        option :format, type: :string, aliases: :f, desc: "Format line output"
        option :uniq, type: :boolean, aliases: :u, desc: "Remove duplicated lines"
        option :count, type: :boolean, default: true, desc: "Show errors count"
        option :junit_output_path, type: :string, desc: "Output failures to XML file formatted for JUnit"
        option :sorbet, type: :string, desc: "Path to custom Sorbet bin"
        option :sorbet_options, type: :string, default: "", desc: "Pass options to Sorbet"
        option :ignore_errors, type: :string, desc: "Path to ignored errors file (default: sorbet/ignored_errors.cfg)"
        def tc(*paths_to_select)
          context = context_requiring_sorbet!
          limit = options[:limit]
          sort = options[:sort]
          code = options[:code]
          uniq = options[:uniq]
          format = options[:format]
          count = options[:count]
          junit_output_path = options[:junit_output_path]
          sorbet = options[:sorbet]

          ignore_errors_path = options[:ignore_errors]
          ignore_errors_path ||= Spoom::Sorbet::Errors::DEFAULT_IGNORED_ERRORS_PATH if File.exist?(
            File.join(context.absolute_path, Spoom::Sorbet::Errors::DEFAULT_IGNORED_ERRORS_PATH),
          )
          ignored_errors = if ignore_errors_path
            path = File.expand_path(ignore_errors_path, context.absolute_path)
            Spoom::Sorbet::Errors.parse_ignored_errors(path)
          end

          unless limit || code || sort || ignored_errors
            result = T.unsafe(context).srb_tc(
              *options[:sorbet_options].split(" "),
              capture_err: false,
              sorbet_bin: sorbet,
            )

            say_error(result.err, status: nil, nl: false)
            exit(result.status)
          end

          error_url_base = Spoom::Sorbet::Errors::DEFAULT_ERROR_URL_BASE
          result = T.unsafe(context).srb_tc(
            *options[:sorbet_options].split(" "),
            "--error-url-base=#{error_url_base}",
            capture_err: true,
            sorbet_bin: sorbet,
          )

          if result.status
            say_error(result.err, status: nil, nl: false)
            if junit_output_path
              doc = Spoom::Sorbet::Errors.to_junit_xml([])
              file = File.open(junit_output_path, "w")
              doc.write(output: file, indent: 2)
              file.close
            end
            exit(0)
          end

          unless result.exit_code == 100
            # Sorbet will return exit code 100 if there are type checking errors.
            # If Sorbet returned something else, it means it didn't terminate normally.
            say_error(result.err, status: nil, nl: false)
            exit(1)
          end

          errors = Spoom::Sorbet::Errors::Parser.parse_string(result.err, error_url_base: error_url_base)
          errors_count = errors.size

          errors = errors.select { |e| e.code == code } if code

          unless paths_to_select.empty?
            errors.select! do |error|
              paths_to_select.any? { |path_to_select| error.file&.start_with?(path_to_select) }
            end
          end

          ignored_count = 0
          if ignored_errors
            matched = Set.new #: Set[[Integer, String, Integer]]
            active, ignored = errors.partition do |e|
              err_code = e.code
              err_file = e.file
              err_line = e.line
              if err_code && err_file && err_line && ignored_errors.include?([err_code, err_file, err_line])
                matched << [err_code, err_file, err_line]
                false
              else
                true
              end
            end
            ignored_count = ignored.size
            errors = active

            stale = ignored_errors - matched
            unless stale.empty?
              stale.each do |entry|
                say_error("Stale entry in ignore file: #{entry[0]}:#{entry[1]}:#{entry[2]}", status: nil)
              end
              exit(1)
            end
          end

          errors = case sort
          when SORT_CODE
            Spoom::Sorbet::Errors.sort_errors_by_code(errors)
          when SORT_LOC
            errors.sort
          else
            errors # preserve natural sort
          end

          errors = T.must(errors.slice(0, limit)) if limit

          lines = errors.map { |e| format_error(e, format || DEFAULT_FORMAT) }
          lines = lines.uniq if uniq

          lines.each do |line|
            say_error(line, status: nil)
          end

          if junit_output_path
            doc = Spoom::Sorbet::Errors.to_junit_xml(errors)
            file = File.open(junit_output_path, "w")
            doc.write(output: file, indent: 2)
            file.close
          end

          if count
            parts = []
            if errors_count != errors.size + ignored_count
              parts << "#{errors.size} shown"
            end
            parts << "#{ignored_count} ignored" if ignored_count > 0
            if parts.empty?
              say_error("Errors: #{errors_count}", status: nil)
            else
              parts << "#{errors_count} total"
              say_error("Errors: #{parts.join(", ")}", status: nil)
            end
          end

          exit(errors.empty? ? 0 : 1)
        rescue Spoom::Sorbet::Error::Segfault => error
          say_error(<<~ERR, status: nil)
            #{red("!!! Sorbet exited with code #{error.result.exit_code} - SEGFAULT !!!")}

            This is most likely related to a bug in Sorbet.
          ERR

          exit(error.result.exit_code)
        rescue Spoom::Sorbet::Error::Killed => error
          say_error(<<~ERR, status: nil)
            #{red("!!! Sorbet exited with code #{error.result.exit_code} - KILLED !!!")}
          ERR

          exit(error.result.exit_code)
        end

        no_commands do
          def format_error(error, format)
            line = format
            line = line.gsub("%C", yellow(error.code.to_s))
            line = line.gsub("%F", error.file)
            line = line.gsub("%L", error.line.to_s)
            line = line.gsub("%M", colorize_message(error.message))
            line
          end

          def colorize_message(message)
            return message unless color?

            cyan = false #: bool
            word = StringIO.new
            message.chars.each do |c|
              if c == "`"
                cyan = !cyan
                next
              end
              word << (cyan ? cyan(c) : red(c))
            end
            word.string
          end
        end
      end
    end
  end
end
