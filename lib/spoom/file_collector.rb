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
    sig do
      params(
        allow_extensions: T::Array[String],
        exclude_patterns: T::Array[String],
      ).void
    end
    def initialize(allow_extensions: [], exclude_patterns: [])
      @files = T.let([], T::Array[String])
      @allow_extensions = allow_extensions
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
      @allow_extensions.none? { |allowed| extension == allowed }
    end

    sig { params(path: String).returns(T::Boolean) }
    def excluded_path?(path)
      @exclude_patterns.any? { |pattern| File.fnmatch?(pattern, path) }
    end
  end
end
