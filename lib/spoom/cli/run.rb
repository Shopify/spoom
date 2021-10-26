# typed: true
# frozen_string_literal: true

module Spoom
  module Cli
    class Run < Thor
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
      option :sorbet, type: :string, desc: "Path to custom Sorbet bin"
      def tc(*arg)
        in_sorbet_project!

        path = exec_path
        limit = options[:limit]
        sort = options[:sort]
        code = options[:code]
        uniq = options[:uniq]
        format = options[:format]
        count = options[:count]
        sorbet = options[:sorbet]

        unless limit || code || sort
          output, status, exit_code = T.unsafe(Spoom::Sorbet).srb_tc(
            *arg,
            path: path,
            capture_err: false,
            sorbet_bin: sorbet
          )

          check_sorbet_segfault(exit_code)
          say_error(output, status: nil, nl: false)
          exit(status)
        end

        output, status, exit_code = T.unsafe(Spoom::Sorbet).srb_tc(
          *arg,
          path: path,
          capture_err: true,
          sorbet_bin: sorbet
        )

        check_sorbet_segfault(exit_code)

        if status
          say_error(output, status: nil, nl: false)
          exit(0)
        end

        errors = Spoom::Sorbet::Errors::Parser.parse_string(output)
        errors_count = errors.size

        errors = case sort
        when SORT_CODE
          Spoom::Sorbet::Errors.sort_errors_by_code(errors)
        when SORT_LOC
          errors.sort
        else
          errors # preserve natural sort
        end

        errors = errors.select { |e| e.code == code } if code
        errors = T.must(errors.slice(0, limit)) if limit

        lines = errors.map { |e| format_error(e, format || DEFAULT_FORMAT) }
        lines = lines.uniq if uniq

        lines.each do |line|
          say_error(line, status: nil)
        end

        if count
          if errors_count == errors.size
            say_error("Errors: #{errors_count}", status: nil)
          else
            say_error("Errors: #{errors.size} shown, #{errors_count} total", status: nil)
          end
        end

        exit(1)
      end

      no_commands do
        def format_error(error, format)
          line = format
          line = line.gsub(/%C/, yellow(error.code.to_s))
          line = line.gsub(/%F/, error.file)
          line = line.gsub(/%L/, error.line.to_s)
          line = line.gsub(/%M/, colorize_message(error.message))
          line
        end

        def colorize_message(message)
          return message unless color?

          cyan = T.let(false, T::Boolean)
          word = StringIO.new
          message.chars.each do |c|
            if c == '`'
              cyan = !cyan
              next
            end
            word << (cyan ? c.cyan : c.red)
          end
          word.string
        end
      end
    end
  end
end
