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

      VALID_STRICTNESS = T.let([
        STRICTNESS_IGNORE,
        STRICTNESS_FALSE,
        STRICTNESS_TRUE,
        STRICTNESS_STRICT,
        STRICTNESS_STRONG,
        STRICTNESS_INTERNAL,
      ].freeze, T::Array[String])

      SIGIL_REGEXP = T.let(/^#\s*typed\s*:\s*(\w*)\s*$/.freeze, Regexp)

      # returns the full sigil comment string for the passed strictness
      sig { params(strictness: String).returns(String) }
      def self.sigil_string(strictness)
        "# typed: #{strictness}"
      end

      # returns true if the passed string is a valid strictness (else false)
      sig { params(strictness: String).returns(T::Boolean) }
      def self.valid_strictness?(strictness)
        VALID_STRICTNESS.include?(strictness.strip)
      end

      # returns the strictness of a sigil in the passed file content string (nil if no sigil)
      sig { params(content: String).returns(T.nilable(String)) }
      def self.strictness_in_content(content)
        SIGIL_REGEXP.match(content)&.[](1)
      end

      # returns a string which is the passed content but with the sigil updated to a new strictness
      sig { params(content: String, new_strictness: String).returns(String) }
      def self.update_sigil(content, new_strictness)
        content.sub(SIGIL_REGEXP, sigil_string(new_strictness))
      end

      # returns a string containing the strictness of a sigil in a file at the passed path
      # * returns nil if no sigil
      sig { params(path: T.any(String, Pathname)).returns(T.nilable(String)) }
      def self.file_strictness(path)
        return nil unless File.exist?(path)
        content = File.read(path)
        strictness_in_content(content)
      end

      # changes the sigil in the file at the passed path to the specified new strictness
      sig { params(path: T.any(String, Pathname), new_strictness: String).returns(T::Boolean) }
      def self.change_sigil_in_file(path, new_strictness)
        content = File.read(path)
        new_content = update_sigil(content, new_strictness)

        File.write(path, new_content)

        strictness_in_content(new_content) == new_strictness
      end

      # changes the sigil to have a new strictness in a list of files
      sig { params(path_list: T::Array[String], new_strictness: String).returns(T::Array[String]) }
      def self.change_sigil_in_files(path_list, new_strictness)
        path_list.filter do |path|
          change_sigil_in_file(path, new_strictness)
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
      def self.files_with_sigil_strictness(directory, strictness, extension: ".rb")
        paths = Dir.glob("#{File.expand_path(directory)}/**/*#{extension}").sort.uniq
        paths.filter do |path|
          file_strictness(path) == strictness
        end
      end
    end
  end
end
