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

      desc "bump DIRECTORY", "Change Sorbet sigils from one strictness to another when no errors"
      option :from, type: :string, default: Spoom::Sorbet::Sigils::STRICTNESS_FALSE,
        desc: "Change only files from this strictness"
      option :to, type: :string, default: Spoom::Sorbet::Sigils::STRICTNESS_TRUE,
        desc: "Change files to this strictness"
      option :force, type: :boolean, default: false, aliases: :f,
        desc: "Change strictness without type checking"
      option :sorbet, type: :string, desc: "Path to custom Sorbet bin"
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

        directory = File.expand_path(directory)
        files_to_bump = Sorbet::Sigils.files_with_sigil_strictness(directory, from)
        Sorbet::Sigils.change_sigil_in_files(files_to_bump, to)

        return if force

        output, no_errors = Sorbet.srb_tc(path: exec_path, capture_err: true, sorbet_bin: options[:sorbet])

        return if no_errors

        errors = Sorbet::Errors::Parser.parse_string(output)

        files_with_errors = errors.map do |err|
          path = File.expand_path(err.file)
          next unless path.start_with?(directory)
          next unless File.file?(path)
          path
        end.compact.uniq

        Sorbet::Sigils.change_sigil_in_files(files_with_errors, from)
      end
    end
  end
end
