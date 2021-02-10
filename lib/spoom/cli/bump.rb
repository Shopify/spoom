# typed: true
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
      option :dry, type: :boolean, default: false, aliases: :d,
        desc: "Only display what would happen, do not actually change sigils"
      option :only, type: :string, default: nil, aliases: :o,
        desc: "Only change specified list (one file by line)"
      option :suggest_bump_command, type: :string,
        desc: "Command to suggest if files can be bumped"
      sig { params(directory: String).void }
      def bump(directory = ".")
        in_sorbet_project!

        from = options[:from]
        to = options[:to]
        force = options[:force]
        dry = options[:dry]
        only = options[:only]
        cmd = options[:suggest_bump_command]
        exec_path = File.expand_path(self.exec_path)

        unless Sorbet::Sigils.valid_strictness?(from)
          say_error("Invalid strictness #{from} for option --from")
          exit(1)
        end

        unless Sorbet::Sigils.valid_strictness?(to)
          say_error("Invalid strictness #{to} for option --to")
          exit(1)
        end

        $stderr.puts("Checking files...")

        directory = File.expand_path(directory)
        files_to_bump = Sorbet::Sigils.files_with_sigil_strictness(directory, from)

        files_from_config = config_files(path: exec_path)
        files_to_bump.select! { |file| files_from_config.include?(file) }

        if only
          list = File.read(only).lines.map { |file| File.expand_path(file.strip) }
          files_to_bump.select! { |file| list.include?(File.expand_path(file)) }
        end

        $stderr.puts("\n")

        if files_to_bump.empty?
          $stderr.puts("No file to bump from #{from} to #{to}")
          exit(0)
        end

        Sorbet::Sigils.change_sigil_in_files(files_to_bump, to)

        if force
          print_changes(files_to_bump, command: cmd, from: from, to: to, dry: dry, path: exec_path)
          undo_changes(files_to_bump, from) if dry
          exit(files_to_bump.empty?)
        end

        output, no_errors = Sorbet.srb_tc(path: exec_path, capture_err: true, sorbet_bin: options[:sorbet])

        if no_errors
          print_changes(files_to_bump, command: cmd, from: from, to: to, dry: dry, path: exec_path)
          undo_changes(files_to_bump, from) if dry
          exit(files_to_bump.empty?)
        end

        errors = Sorbet::Errors::Parser.parse_string(output)

        files_with_errors = errors.map do |err|
          path = File.expand_path(err.file)
          next unless path.start_with?(directory)
          next unless File.file?(path)
          path
        end.compact.uniq

        undo_changes(files_with_errors, from)

        files_changed = files_to_bump - files_with_errors
        print_changes(files_changed, command: cmd, from: from, to: to, dry: dry, path: exec_path)
        undo_changes(files_to_bump, from) if dry
        exit(files_changed.empty?)
      end

      no_commands do
        def print_changes(files, command:, from: "false", to: "true", dry: false, path: File.expand_path("."))
          if files.empty?
            $stderr.puts("No file to bump from #{from} to #{to}")
            return
          end
          $stderr.write(dry ? "Can bump" : "Bumped")
          $stderr.write(" #{files.size} file#{'s' if files.size > 1}")
          $stderr.puts(" from #{from} to #{to}:")
          files.each do |file|
            file_path = Pathname.new(file).relative_path_from(path)
            $stderr.puts(" + #{file_path}")
          end
          if dry && command
            $stderr.puts("\nRun `#{command}` to bump them")
          elsif dry
            $stderr.puts("\nRun `spoom bump --from #{from} --to #{to}` to bump them")
          end
        end

        def undo_changes(files, from_strictness)
          Sorbet::Sigils.change_sigil_in_files(files, from_strictness)
        end

        def config_files(path: ".")
          config = sorbet_config
          files = Sorbet.srb_files(config, path: path)
          files.map { |file| File.expand_path(file) }
        end
      end
    end
  end
end
