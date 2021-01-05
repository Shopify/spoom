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
      option :sort, type: :string, aliases: :s, desc: "Sort errors", enum: SORT_ENUM, lazy_default: SORT_LOC
      option :format, type: :string, aliases: :f, desc: "Format line output"
      option :count, type: :boolean, default: true, desc: "Show errors count"
      def tc
        in_sorbet_project!

        path = exec_path
        limit = options[:limit]
        sort = options[:sort]
        code = options[:code]
        format = options[:format]
        count = options[:count]

        unless limit || code || sort || format || count
          exit(Spoom::Sorbet.srb_tc(path: path, capture_err: false).last)
        end

        output, status = Spoom::Sorbet.srb_tc(path: path, capture_err: true)
        if status
          $stderr.print(output)
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

        errors.each do |error|
          $stderr.puts format_error(error, format || DEFAULT_FORMAT)
        end

        if count
          if errors_count == errors.size
            $stderr.puts "Errors: #{errors_count}"
          else
            $stderr.puts "Errors: #{errors.size} shown, #{errors_count} total"
          end
        end

        exit(1)
      end

      no_commands do
        def format_error(error, format)
          line = format
          line = line.gsub(/%C/, colorize(error.code.to_s, :yellow))
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
