# typed: strict
# frozen_string_literal: true

module Spoom
  class Snippet
    extend T::Sig

    class << self
      extend T::Sig

      sig { params(string: String, file: String).returns(Snippet) }
      def from_string(string, file: "-")
        snippet = Snippet.new(file)

        Prism.parse_comments(string).each do |comment|
          comment_string = comment.slice
          name, args_string, offset = match_command(comment_string)
          next unless name && args_string && offset

          location = Spoom::Location.from_prism(file, comment.location)
          target_location = target_location(comment_string, location, offset)

          snippet.commands << Snippet::Command.new(name, args_string, location, target_location)
        end

        snippet
      end

      sig { params(file: String).returns(Snippet) }
      def from_file(file)
        from_string(File.read(file), file: file)
      end

      private

      sig do
        params(comment_string: String).returns(T.nilable([String, String, String]))
      end
      def match_command(comment_string)
        match = comment_string.match(/^\s*#\s*(?<offset>\^*)\s*(?<name>\w+): (?<args_string>.+)$/)
        return unless match

        [
          T.must(match[:name]),
          T.must(match[:args_string]),
          T.must(match[:offset]),
        ]
      end

      sig do
        params(
          comment_string: String,
          comment_location: Spoom::Location,
          offset_match: String,
        ).returns(Spoom::Location)
      end
      def target_location(comment_string, comment_location, offset_match)
        if offset_match.empty?
          Spoom::Location.new(
            comment_location.file,
            start_line: comment_location.start_line,
            end_line: comment_location.end_line,
          )
        else
          start = (comment_location.start_column || 0) + T.must(comment_string.index("^"))
          offset = offset_match.count("^")
          Spoom::Location.new(
            comment_location.file,
            start_line: (comment_location.start_line || 1) - 1,
            end_line: (comment_location.end_line || 1) - 1,
            start_column: start,
            end_column: start + offset,
          )
        end
      end
    end

    sig { returns(String) }
    attr_reader :file

    sig { returns(T::Array[Command]) }
    attr_reader :commands

    sig { params(file: String, commands: T::Array[Command]).void }
    def initialize(file, commands = [])
      @file = file
      @commands = commands
    end

    sig { params(content: String, replacements: T::Array[[Command, String]]).returns(String) }
    def render(content, replacements)
      output = []

      content.lines.each_with_index do |line, i|
        replacements.each do |command, text|
          loc = command.location

          next if (i + 1) < T.must(loc.start_line) || (i + 1) > T.must(loc.start_line)

          line[command.location.start_column..command.location.end_column] =
            "#{command.location.string.sub(command.args_string || "", text)}\n"
        end

        output << line
        output
      end

      output.join
    end

    class Command
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(T.nilable(String)) }
      attr_reader :args_string

      sig { returns(Spoom::Location) }
      attr_reader :location

      sig { returns(Spoom::Location) }
      attr_reader :target_location

      sig do
        params(
          name: String,
          args_string: T.nilable(String),
          location: Spoom::Location,
          target_location: Spoom::Location,
        ).void
      end
      def initialize(name, args_string, location, target_location)
        @name = name
        @args_string = args_string
        @location = location
        @target_location = target_location
      end

      sig { override.returns(String) }
      def to_s
        "#{location}: #{name}: #{args_string} -> #{target_location}"
      end
    end
  end
end
