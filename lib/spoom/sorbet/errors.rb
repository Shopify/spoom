# typed: true
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Errors
      # Parse errors from Sorbet output
      class Parser
        HEADER = [
          "👋 Hey there! Heads up that this is not a release build of sorbet.",
          "Release builds are faster and more well-supported by the Sorbet team.",
          "Check out the README to learn how to build Sorbet in release mode.",
          "To forcibly silence this error, either pass --silence-dev-message,",
          "or set SORBET_SILENCE_DEV_MESSAGE=1 in your shell environment.",
        ]

        def self.parse_string(output)
          parser = Spoom::Sorbet::Errors::Parser.new
          parser.parse(output)
        end

        def initialize
          @errors = []
          @current_error = nil
        end

        def parse(output)
          output.each_line do |line|
            break @errors if /^No errors! Great job\./.match?(line)
            break @errors if /^Errors: /.match?(line)
            next if HEADER.include?(line.strip)

            next if line == "\n"

            if leading_spaces(line) == 0
              close_error if @current_error
              open_error(line)
              next
            end

            append_error(line)
          end
          close_error if @current_error
          @errors
        end

        def leading_spaces(line)
          line.index(/[^ ]/)
        end

        def open_error(line)
          raise "Error: Already parsing an error!" if @current_error
          @current_error = Error.from_error_line(line)
        end

        def close_error
          return unless @current_error
          @errors << @current_error
          @current_error = nil
        end

        def append_error(line)
          raise "Error: Not already parsing an error!" unless @current_error
          @current_error.more << line
        end
      end

      class Error
        include Comparable

        attr_reader :file, :line, :message, :code, :details, :more

        def initialize(file, line, message, code, more = [])
          @file = file
          @line = line
          @message = message
          @code = code
          @more = more
        end

        def self.from_error_line(line)
          file, rest = line.split(":", 2)
          line, rest = rest&.split(": ", 2)
          message, code = rest&.split(%r{ https://srb\.help/}, 2)
          Error.new(file, line&.to_i, message, code&.to_i)
        end

        def <=>(other)
          return 0 unless other.is_a?(Error)
          return line <=> other.line if file == other.file
          file <=> other.file
        end

        def to_s
          "#{file}:#{line}: #{message} (#{code})"
        end
      end
    end
  end
end
