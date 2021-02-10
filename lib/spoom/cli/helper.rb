# typed: strict
# frozen_string_literal: true

require "fileutils"
require "pathname"
require "stringio"

module Spoom
  module Cli
    module Helper
      extend T::Sig
      include Thor::Shell

      # Print `message` on `$stderr`
      #
      # The message is prefixed by a status (default: `Error`).
      sig { params(message: String, status: String).void }
      def say_error(message, status = "Error")
        buffer = StringIO.new
        buffer << "#{red(status)}: #{message}"
        buffer << "\n" unless message.end_with?("\n")

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
            "not in a Sorbet project (#{yellow(sorbet_config_file)} not found)\n\n" \
            "When running spoom from another path than the project's root, " \
            "use #{blue('--path PATH')} to specify the path to the root."
          )
          Kernel.exit(1)
        end
      end

      # Return the path specified through `--path`
      sig { returns(String) }
      def exec_path
        T.unsafe(self).options[:path] # TODO: requires_ancestor
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

      # Is the `--color` option true?
      sig { returns(T::Boolean) }
      def color?
        T.unsafe(self).options[:color] # TODO: requires_ancestor
      end

      # Colorize a string if `color?`
      sig { params(string: String, color: Symbol).returns(String) }
      def colorize(string, color)
        return string unless color?
        string.colorize(color)
      end

      sig { params(string: String).returns(String) }
      def blue(string)
        colorize(string, :blue)
      end

      sig { params(string: String).returns(String) }
      def gray(string)
        colorize(string, :light_black)
      end

      sig { params(string: String).returns(String) }
      def green(string)
        colorize(string, :green)
      end

      sig { params(string: String).returns(String) }
      def red(string)
        colorize(string, :red)
      end

      sig { params(string: String).returns(String) }
      def yellow(string)
        colorize(string, :yellow)
      end
    end
  end
end
