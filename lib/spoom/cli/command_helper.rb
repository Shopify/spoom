# typed: strict
# frozen_string_literal: true

require 'stringio'

module Spoom
  module Cli
    module CommandHelper
      extend T::Sig
      include Thor::Shell

      # Print `message` on `$stderr`
      #
      # The message is prefixed by a status (default: `Error`).
      sig { params(message: String, status: String).void }
      def say_error(message, status = "Error")
        status = set_color(status, :red)

        buffer = StringIO.new
        buffer << "#{status}: #{message}"
        buffer << "\n" unless message.end_with?("\n")

        $stderr.print(buffer.string)
        $stderr.flush
      end

      # Is `spoom` ran inside a project with a `sorbet/config` file?
      sig { returns(T::Boolean) }
      def in_sorbet_project?
        File.file?(Spoom::Config::SORBET_CONFIG)
      end

      # Enforce that `spoom` is ran inside a project with a `sorbet/config` file
      #
      # Display an error message and exit otherwise.
      sig { void }
      def in_sorbet_project!
        unless in_sorbet_project?
          say_error("not in a Sorbet project (no sorbet/config)")
          Kernel.exit(1)
        end
      end
    end
  end
end
