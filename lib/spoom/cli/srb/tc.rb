# typed: true
# frozen_string_literal: true

require "rexml/document"

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

          unless limit || code || sort
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
              write_errors_to_xml([], path: junit_output_path)
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
            write_errors_to_xml(errors, path: junit_output_path)
          end

          if count
            if errors_count == errors.size
              say_error("Errors: #{errors_count}", status: nil)
            else
              say_error("Errors: #{errors.size} shown, #{errors_count} total", status: nil)
            end
          end

          exit(1)
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

          def write_errors_to_xml(errors, path:)
            doc = REXML::Document.new
            doc << REXML::XMLDecl.new
            testsuite_element = doc.add_element("testsuite")
            testsuite_element.add_attributes(
              "name" => "Sorbet",
              "failures" => errors.size,
            )

            if errors.empty?
              # Avoid creating an empty report when there are no errors so that
              # reporting tools know that the type checking ran successfully.
              testcase_element = testsuite_element.add_element("testcase")
              testcase_element.add_attributes(
                "name" => "Typecheck",
                "tests" => 1,
              )
            else
              errors.each do |error|
                testcase_element = testsuite_element.add_element("testcase")
                # Unlike traditional test suites, we can't report all tests
                # regardless of outcome; we only have errors to report. As a
                # result we reinterpret the definitions of the test properties
                # bit: the error message becomes the test name and the full error
                # info gets plugged into the failure body along with file/line
                # information (displayed in Jenkins as the "Stacktrace" for the
                # error).
                testcase_element.add_attributes(
                  "name" => error.message,
                  "file" => error.file,
                  "line" => error.line,
                )
                failure_element = testcase_element.add_element("failure")
                failure_element.add_attributes(
                  "type" => error.code,
                )
                explanation_lines = [
                  "In file #{error.file}:\n",
                ] + error.more
                explanation_text = explanation_lines.join("").chomp
                # Use CDATA so that parsers know the whitespace is significant.
                failure_element.add(REXML::CData.new(explanation_text))
              end
            end

            xml_buffer = StringIO.new
            doc.write(output: xml_buffer, indent: 2)
            File.write(path, xml_buffer.string)
          end
        end
      end
    end
  end
end
