# typed: strict
# frozen_string_literal: true

require 'find'
require 'open3'

require_relative 'base'

module Spoom
  module Cli
    module Commands
      class Bump < Base
        extend T::Sig

        default_task :bump

        desc "bump", "change Sorbet sigils from one strictness to another when no errors"
        option :from, type: :string
        option :to, type: :string
        option :force, type: :boolean, default: false, aliases: :f
        sig { params(directory: String).void }
        def bump(directory = ".")
          from = options[:from] ? options[:from] : Sorbet::Sigils::STRICTNESS_FALSE
          to = options[:to] ? options[:to] : Sorbet::Sigils::STRICTNESS_TRUE
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

          return [] if force

          output, no_errors = Sorbet.srb_tc(path: File.expand_path(directory), capture_err: true)

          return [] if no_errors

          errors = Sorbet::Errors::Parser.parse_string(output)

          files_with_errors = errors.map do |err|
            File.join(directory, err.file)
          end.compact

          Sorbet::Sigils.change_sigil_in_files(files_with_errors, from)
        end

        no_commands do
        end
      end
    end
  end
end
