# typed: strict
# frozen_string_literal: true

# The term "sigil" refers to the magic comment at the top of the file that has the form `# typed: <strictness>`,
# where "strictness" represents the level at which Sorbet will report errors
# See https://sorbet.org/docs/static for a more complete explanation
module Spoom
  module Sorbet
    module Sigils
      extend T::Sig

      STRICTNESS_IGNORE = "ignore"
      STRICTNESS_FALSE = "false"
      STRICTNESS_TRUE = "true"
      STRICTNESS_STRICT = "strict"
      STRICTNESS_STRONG = "strong"
      STRICTNESS_INTERNAL = "__STDLIB_INTERNAL"

      DEFAULT_STRICTNESS = STRICTNESS_FALSE

      VALID_STRICTNESS = T.let([
        STRICTNESS_IGNORE,
        STRICTNESS_FALSE,
        STRICTNESS_TRUE,
        STRICTNESS_STRICT,
        STRICTNESS_STRONG,
        STRICTNESS_INTERNAL,
      ].freeze, T::Array[String])

      SIGIL_REGEXP = T.let(/^#[\ t]*typed[\ t]*:[ \t]*(\w*)[ \t]*/.freeze, Regexp)

      class << self
        extend T::Sig

        # returns the full sigil comment string for the passed strictness
        sig { params(strictness: String).returns(String) }
        def sigil_string(strictness)
          "# typed: #{strictness}"
        end

        # returns true if the passed string is a valid strictness (else false)
        sig { params(strictness: String).returns(T::Boolean) }
        def valid_strictness?(strictness)
          VALID_STRICTNESS.include?(strictness.strip)
        end

        # returns the strictness of a sigil in the passed file content string (nil if no sigil)
        sig { params(content: String).returns(T.nilable(String)) }
        def strictness_in_content(content)
          SIGIL_REGEXP.match(content)&.[](1)
        end

        # returns a string which is the passed content but with the sigil updated to a new strictness
        sig { params(content: String, new_strictness: String).returns(String) }
        def update_sigil(content, new_strictness)
          content.sub(SIGIL_REGEXP, sigil_string(new_strictness))
        end

        sig { params(content: String, new_strictness: String).returns(String) }
        def prepend_sigil(content, new_strictness)
          sigil_string(new_strictness) + "\n" + content
        end

        sig { params(content: String).returns(String) }
        def remove_sigil(content)
          sigil_with_newline = /#{SIGIL_REGEXP}\n/
          content.gsub(sigil_with_newline, "")
        end

        # returns a string containing the strictness of a sigil in a file at the passed path
        # * returns nil if no sigil
        sig { params(path: T.any(String, Pathname)).returns(T.nilable(String)) }
        def file_strictness(path)
          return nil unless File.file?(path)

          content = File.read(path, encoding: Encoding::ASCII_8BIT)
          strictness_in_content(content) || DEFAULT_STRICTNESS
        end

        # changes the sigil in the file at the passed path to the specified new strictness
        sig { params(path: T.any(String, Pathname), new_strictness: T.nilable(String)).returns(T.nilable(String)) }
        def change_sigil_in_file(path, new_strictness)
          content = File.read(path, encoding: Encoding::ASCII_8BIT)
          old_sigil = strictness_in_content(content)
          new_content = update_content(content, old_sigil, new_strictness)
          File.write(path, new_content, encoding: Encoding::ASCII_8BIT)

          old_sigil
        end

        sig { params(old_content: String, old_sigil: T.nilable(String), new_sigil: T.nilable(String)).returns(String) }
        def update_content(old_content, old_sigil, new_sigil)
          return remove_sigil(old_content) if new_sigil.nil?

          if old_sigil
            update_sigil(old_content, new_sigil)
          else
            prepend_sigil(old_content, new_sigil)
          end
        end

        # changes the sigil to have a new strictness in a list of files
        sig { params(path_list: T::Hash[String, String]).returns(T::Hash[String, String]) }
        def change_sigil_in_files(path_list)
          path_list.each_with_object({}) do |path_and_strictness, updated_from|
            path, strictness = path_and_strictness
            old_sigil = change_sigil_in_file(path, strictness)
            updated_from[path] = old_sigil
          end
        end

        # finds all files in the specified directory with the passed strictness
        sig do
          params(
            directory: T.any(String, Pathname),
            strictness: String,
            extension: String
          ).returns(T::Array[String])
        end
        def files_with_sigil_strictness(directory, strictness, extension: ".rb")
          paths = Dir.glob("#{File.expand_path(directory)}/**/*#{extension}").sort.uniq
          paths.filter do |path|
            file_strictness(path) == strictness
          end
        end
      end
    end
  end
end
