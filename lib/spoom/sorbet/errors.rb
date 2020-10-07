# typed: true
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Errors
      # Parse errors from Sorbet output
      class Parser
        extend T::Sig

        HEADER = [
          "👋 Hey there! Heads up that this is not a release build of sorbet.",
          "Release builds are faster and more well-supported by the Sorbet team.",
          "Check out the README to learn how to build Sorbet in release mode.",
          "To forcibly silence this error, either pass --silence-dev-message,",
          "or set SORBET_SILENCE_DEV_MESSAGE=1 in your shell environment.",
        ]

        ERROR_LINE_MATCH_REGEX = %r{
          ^         # match beginning of line
          (\S[^:]*) # capture filename as something that starts with a non-space character
                    # followed by anything that is not a colon character
          :         # match the filename - line number seperator
          (\d+)     # capture the line number
          :\s       # match the line number - error message separator
          (.*)      # capture the error message
          \shttps://srb.help/ # match the error code url prefix
          (\d+)     # capture the error code
          $         # match end of line
        }x.freeze

        sig { params(output: String).returns(T::Array[Error]) }
        def self.parse_string(output)
          parser = Spoom::Sorbet::Errors::Parser.new
          parser.parse(output)
        end

        sig { void }
        def initialize
          @errors = []
          @current_error = nil
        end

        sig { params(output: String).returns(T::Array[Error]) }
        def parse(output)
          output.each_line do |line|
            break if /^No errors! Great job\./.match?(line)
            break if /^Errors: /.match?(line)
            next if HEADER.include?(line.strip)

            next if line == "\n"

            if (error = match_error_line(line))
              close_error if @current_error
              open_error(error)
              next
            end

            append_error(line) if @current_error
          end
          close_error if @current_error
          @errors
        end

        private

        sig { params(line: String).returns(T.nilable(Error)) }
        def match_error_line(line)
          match = line.match(ERROR_LINE_MATCH_REGEX)
          return unless match

          file, line, message, code = match.captures
          Error.new(file, line&.to_i, message, code&.to_i)
        end

        sig { params(error: Error).void }
        def open_error(error)
          raise "Error: Already parsing an error!" if @current_error
          @current_error = error
        end

        sig { void }
        def close_error
          raise "Error: Not already parsing an error!" unless @current_error
          @errors << @current_error
          @current_error = nil
        end

        sig { params(line: String).void }
        def append_error(line)
          raise "Error: Not already parsing an error!" unless @current_error
          @current_error.more << line
        end
      end

      class Error
        include Comparable
        extend T::Sig

        sig { returns(T.nilable(String)) }
        attr_reader :file, :message

        sig { returns(T.nilable(Integer)) }
        attr_reader :line, :code

        sig { returns(T::Array[String]) }
        attr_reader :more

        sig do
          params(
            file: T.nilable(String),
            line: T.nilable(Integer),
            message: T.nilable(String),
            code: T.nilable(Integer),
            more: T::Array[String]
          ).void
        end
        def initialize(file, line, message, code, more = [])
          @file = file
          @line = line
          @message = message
          @code = code
          @more = more
        end

        sig { params(other: T.untyped).returns(Integer) }
        def <=>(other)
          return 0 unless other.is_a?(Error)
          [file, line, code, message] <=> [other.file, other.line, other.code, other.message]
        end

        sig { returns(String) }
        def to_s
          "#{file}:#{line}: #{message} (#{code})"
        end
      end
    end
  end
end
