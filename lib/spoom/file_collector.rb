# typed: strict
# frozen_string_literal: true

module Spoom
  class FileCollector
    extend T::Sig

    sig { returns(T::Array[String]) }
    attr_reader :files

    # Initialize a new file collector
    #
    # If `allow_extensions` is empty, all files are collected.
    # If `allow_extensions` is an array of extensions, only files with one of these extensions are collected.
    #
    # If `allow_mime_types` is empty, all files are collected.
    # If `allow_mime_types` is an array of mimetypes, files without an extension are collected if their mimetype is in
    # the list.
    sig do
      params(
        allow_extensions: T::Array[String],
        allow_mime_types: T::Array[String],
        exclude_patterns: T::Array[String],
      ).void
    end
    def initialize(allow_extensions: [], allow_mime_types: [], exclude_patterns: [])
      @files = T.let([], T::Array[String])
      @allow_extensions = allow_extensions
      @allow_mime_types = allow_mime_types
      @exclude_patterns = exclude_patterns
    end

    sig { params(paths: T::Array[String]).void }
    def visit_paths(paths)
      paths.each { |path| visit_path(path) }
    end

    sig { params(path: String).void }
    def visit_path(path)
      path = clean_path(path)

      return if excluded_path?(path)

      if File.file?(path)
        visit_file(path)
      elsif File.directory?(path)
        visit_directory(path)
      else # rubocop:disable Style/EmptyElse
        # Ignore aliases, sockets, etc.
      end
    end

    private

    sig { params(path: String).returns(String) }
    def clean_path(path)
      Pathname.new(path).cleanpath.to_s
    end

    sig { params(path: String).void }
    def visit_file(path)
      return if excluded_file?(path)

      @files << path
    end

    sig { params(path: String).void }
    def visit_directory(path)
      visit_paths(Dir.glob("#{path}/*"))
    end

    sig { params(path: String).returns(T::Boolean) }
    def excluded_file?(path)
      return false if @allow_extensions.empty?

      extension = File.extname(path)
      if extension.empty?
        return true if @allow_mime_types.empty?

        mime = mime_type_for(path)
        @allow_mime_types.none? { |allowed| mime == allowed }
      else
        @allow_extensions.none? { |allowed| extension == allowed }
      end
    end

    sig { params(path: String).returns(T::Boolean) }
    def excluded_path?(path)
      @exclude_patterns.any? do |pattern|
        # Use `FNM_PATHNAME` so patterns do not match directory separators
        # Use `FNM_EXTGLOB` to allow file globbing through `{a,b}`
        File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
      end
    end

    sig { params(path: String).returns(T.nilable(String)) }
    def mime_type_for(path)
      # The `file` command appears to be hanging on MacOS for some files so we timeout after 1s.
      %x{timeout 1s file --mime-type -b '#{path}'}.split("; ").first&.strip
    end
  end
end
