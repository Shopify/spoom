# typed: false
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

        desc "bump", "bump Sorbet sigils from `false` to `true` when no errors"
        sig { params(directory: String, extension: String).returns(T::Array[String]) }
        def bump(directory = ".", extension = "rb")
          files_to_bump = Bump.files_with_sigil_strictness(directory, "false", extension)

          Bump.change_sigil_in_files(files_to_bump, "true")

          output, no_errors = Spoom::Sorbet.srb_tc(File.expand_path(directory), capture_err: true)

          return [] if no_errors

          errors = Spoom::Sorbet::Errors::Parser.parse_string(output)

          files_with_errors = Bump.file_names_from_error(errors)

          Bump.change_sigil_in_files(files_with_errors, "false")
        end

        no_commands do
          # finds all files in the specified directory with the passed strictness
          sig do
            params(
              directory: T.any(String, Pathname),
              strictness: String,
              extension: String
            )
            .returns(T::Array[String])
          end
          def self.files_with_sigil_strictness(directory, strictness, extension = "rb")
            paths = Dir.glob("#{File.expand_path(directory)}/**/*.#{extension}")

            paths.filter do |path|
              file_strictness(path) == strictness
            end
          end

          # returns an array of the file names present in the passed
          sig { params(errors: T::Array[Spoom::Sorbet::Errors::Error]).returns(T::Array[String]) }
          def self.file_names_from_error(errors)
            errors.map { |err| err.file }
          end

          # returns a string containing the strictness of a sigil in a file at the passed path
          # * returns nil if no sigil
          sig { params(path: T.any(String, Pathname)).returns(T.nilable(String)) }
          def self.file_strictness(path)
            content = File.read(path)
            Spoom::Sorbet::Sigils.strictness(content)
          end

          # changes the sigil in the file at the passed path to the specified new strictness
          sig { params(path: T.any(String, Pathname), new_strictness: String).void }
          def self.change_sigil_in_file(path, new_strictness)
            content = File.read(path)
            File.write(path, Spoom::Sorbet::Sigils.update_sigil(content, new_strictness))
          end

          # changes the sigil to have a new strictness in a list of files
          sig { params(path_list: T::Array[T.any(String, Pathname)], new_strictness: String).returns(T::Array[String]) }
          def self.change_sigil_in_files(path_list, new_strictness)
            path_list.each do |path|
              change_sigil_in_file(path, new_strictness)
            end
          end
        end
      end
    end
  end
end
