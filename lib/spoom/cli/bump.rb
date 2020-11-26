# typed: strict
# frozen_string_literal: true

require 'find'
require 'open3'

module Spoom
  module Cli
    class Bump < Thor
      extend T::Sig
      include Helper

      default_task :bump

      desc "bump DIRECTORY", "change Sorbet sigils from one strictness to another when no errors"
      option :from, type: :string, default: Spoom::Sorbet::Sigils::STRICTNESS_FALSE
      option :to, type: :string, default: Spoom::Sorbet::Sigils::STRICTNESS_TRUE
      option :force, desc: "change strictness without type checking", type: :boolean, default: false, aliases: :f
      sig { params(directory: String).void }
      def bump(directory = ".")
        in_sorbet_project!

        from = options[:from]
        to = options[:to]
        force = options[:force]

        unless Sorbet::Sigils.valid_strictness?(from)
          say_error("Invalid strictness #{from} for option --from")
          exit(1)
        end

        unless Sorbet::Sigils.valid_strictness?(to)
          say_error("Invalid strictness #{to} for option --to")
          exit(1)
        end

        files_to_bump = Sorbet::Sigils.files_with_sigil_strictness(directory, from)
        Sorbet::Sigils.change_sigil_in_files(files_to_bump, to)

        return if force

        output, no_errors = Sorbet.srb_tc(path: exec_path, capture_err: true)

        return if no_errors

        errors = Sorbet::Errors::Parser.parse_string(output)

        files_with_errors = errors.map do |err|
          path = err.file
          File.join(directory, path) if path && File.file?(path)
        end.compact.uniq

        Sorbet::Sigils.change_sigil_in_files(files_with_errors, from)
      end
    end
  end
end
