# typed: strict
# frozen_string_literal: true

require "fileutils"
require "pathname"
require "stringio"

module Spoom
  module Cli
    module Helper
      extend T::Sig
      extend T::Helpers

      include Colorize

      requires_ancestor { Thor }

      # Print `message` on `$stdout`
      sig { params(message: String).void }
      def say(message)
        buffer = StringIO.new
        buffer << highlight(message)
        buffer << "\n" unless message.end_with?("\n")

        $stdout.print(buffer.string)
        $stdout.flush
      end

      # Print `message` on `$stderr`
      #
      # The message is prefixed by a status (default: `Error`).
      sig do
        params(
          message: String,
          status: T.nilable(String),
          nl: T::Boolean
        ).void
      end
      def say_error(message, status: "Error", nl: true)
        buffer = StringIO.new
        buffer << "#{red(status)}: " if status
        buffer << highlight(message)
        buffer << "\n" if nl && !message.end_with?("\n")

        $stderr.print(buffer.string)
        $stderr.flush
      end

      # Is `spoom` ran inside a project with a `sorbet/config` file?
      sig { returns(T::Boolean) }
      def in_sorbet_project?
        File.file?(sorbet_config_file)
      end

      # Enforce that `spoom` is ran inside a project with a `sorbet/config` file
      #
      # Display an error message and exit otherwise.
      sig { void }
      def in_sorbet_project!
        unless in_sorbet_project?
          say_error(
            "not in a Sorbet project (`#{sorbet_config_file}` not found)\n\n" \
            "When running spoom from another path than the project's root, " \
            "use `--path PATH` to specify the path to the root."
          )
          Kernel.exit(1)
        end
      end

      # Return the path specified through `--path`
      sig { returns(String) }
      def exec_path
        options[:path]
      end

      sig { returns(String) }
      def sorbet_config_file
        Pathname.new("#{exec_path}/#{Spoom::Sorbet::CONFIG_PATH}").cleanpath.to_s
      end

      sig { returns(Sorbet::Config) }
      def sorbet_config
        Sorbet::Config.parse_file(sorbet_config_file)
      end

      # Colors

      # Color used to highlight expressions in backticks
      HIGHLIGHT_COLOR = T.let(Spoom::Color::BLUE, Spoom::Color)

      # Is the `--color` option true?
      sig { returns(T::Boolean) }
      def color?
        options[:color]
      end

      sig { params(string: String).returns(String) }
      def highlight(string)
        return string unless color?

        res = StringIO.new
        word = StringIO.new
        in_ticks = T.let(false, T::Boolean)
        string.chars.each do |c|
          if c == '`' && !in_ticks
            in_ticks = true
          elsif c == '`' && in_ticks
            in_ticks = false
            res << colorize(word.string, HIGHLIGHT_COLOR)
            word = StringIO.new
          elsif in_ticks
            word << c
          else
            res << c
          end
        end
        res.string
      end

      # Colorize a string if `color?`
      sig { params(string: String, color: Color).returns(String) }
      def colorize(string, *color)
        return string unless color?
        T.unsafe(self).set_color(string, *color)
      end

      sig { params(string: String).returns(String) }
      def blue(string)
        colorize(string, Color::BLUE)
      end

      sig { params(string: String).returns(String) }
      def gray(string)
        colorize(string, Color::LIGHT_BLACK)
      end

      sig { params(string: String).returns(String) }
      def green(string)
        colorize(string, Color::GREEN)
      end

      sig { params(string: String).returns(String) }
      def red(string)
        colorize(string, Color::RED)
      end

      sig { params(string: String).returns(String) }
      def yellow(string)
        colorize(string, Color::YELLOW)
      end
    end
  end
end
