# typed: strict
# frozen_string_literal: true

module Spoom
  class Context
    # File System features for a context
    module FileSystem
      extend T::Sig
      extend T::Helpers

      requires_ancestor { Context }

      # Returns the absolute path to `relative_path` in the context's directory
      sig { params(relative_path: String).returns(String) }
      def absolute_path_to(relative_path)
        File.join(absolute_path, relative_path)
      end

      # Does the context directory at `absolute_path` exist and is a directory?
      sig { returns(T::Boolean) }
      def exist?
        File.directory?(absolute_path)
      end

      # Create the context directory at `absolute_path`
      sig { void }
      def mkdir!
        FileUtils.rm_rf(absolute_path)
        FileUtils.mkdir_p(absolute_path)
      end

      # List all files in this context matching `pattern`
      sig { params(pattern: String).returns(T::Array[String]) }
      def glob(pattern = "**/*")
        Dir.glob(absolute_path_to(pattern)).map do |path|
          Pathname.new(path).relative_path_from(absolute_path).to_s
        end.sort
      end

      # List all files at the top level of this context directory
      sig { returns(T::Array[String]) }
      def list
        glob("*")
      end

      sig do
        params(
          allow_extensions: T::Array[String],
          allow_mime_types: T::Array[String],
          exclude_patterns: T::Array[String],
        ).returns(T::Array[String])
      end
      def collect_files(allow_extensions: [], allow_mime_types: [], exclude_patterns: [])
        collector = FileCollector.new(
          allow_extensions: allow_extensions,
          allow_mime_types: allow_mime_types,
          exclude_patterns: exclude_patterns,
        )
        collector.visit_path(absolute_path)
        collector.files.map { |file| file.delete_prefix("#{absolute_path}/") }
      end

      # Does `relative_path` point to an existing file in this context directory?
      sig { params(relative_path: String).returns(T::Boolean) }
      def file?(relative_path)
        File.file?(absolute_path_to(relative_path))
      end

      # Return the contents of the file at `relative_path` in this context directory
      #
      # Will raise if the file doesn't exist.
      sig { params(relative_path: String).returns(String) }
      def read(relative_path)
        File.read(absolute_path_to(relative_path))
      end

      # Write `contents` in the file at `relative_path` in this context directory
      #
      # Append to the file if `append` is true.
      sig { params(relative_path: String, contents: String, append: T::Boolean).void }
      def write!(relative_path, contents = "", append: false)
        absolute_path = absolute_path_to(relative_path)
        FileUtils.mkdir_p(File.dirname(absolute_path))
        File.write(absolute_path, contents, mode: append ? "a" : "w")
      end

      # Remove the path at `relative_path` (recursive + force) in this context directory
      sig { params(relative_path: String).void }
      def remove!(relative_path)
        FileUtils.rm_rf(absolute_path_to(relative_path))
      end

      # Move the file or directory from `from_relative_path` to `to_relative_path`
      sig { params(from_relative_path: String, to_relative_path: String).void }
      def move!(from_relative_path, to_relative_path)
        destination_path = absolute_path_to(to_relative_path)
        FileUtils.mkdir_p(File.dirname(destination_path))
        FileUtils.mv(absolute_path_to(from_relative_path), destination_path)
      end

      # Delete this context and its content
      #
      # Warning: it will `rm -rf` the context directory on the file system.
      sig { void }
      def destroy!
        FileUtils.rm_rf(absolute_path)
      end
    end
  end
end
