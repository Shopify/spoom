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

            if leading_spaces(line) == 0
              close_error if @current_error
              open_error(line)
              next
            end

            append_error(line) if @current_error
          end
          close_error if @current_error
          @errors
        end

        private

        sig { params(line: String).returns(T.nilable(Integer)) }
        def leading_spaces(line)
          line.index(/[^ ]/)
        end

        sig { params(line: String).void }
        def open_error(line)
          raise "Error: Already parsing an error!" if @current_error
          @current_error = Error.from_error_line(line)
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

        sig { params(line: String).returns(Error) }
        def self.from_error_line(line)
          file, line, rest = line.split(/: ?/, 3)
          message, code = rest&.split(%r{ https://srb\.help/}, 2)
          Error.new(file, line&.to_i, message, code&.to_i)
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
