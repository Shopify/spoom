# typed: strict
# frozen_string_literal: true

require "fileutils"
require "open3"
require "time"
require "tmpdir"

require_relative "context/bundle"
require_relative "context/exec"
require_relative "context/file_system"
require_relative "context/git"
require_relative "context/sorbet"

module Spoom
  # An abstraction to a Ruby project context
  #
  # A context maps to a directory in the file system.
  # It is used to manipulate files and run commands in the context of this directory.
  class Context
    extend T::Sig

    include Bundle
    include Exec
    include FileSystem
    include Git
    include Sorbet

    class << self
      extend T::Sig

      # Create a new context in the system's temporary directory
      #
      # `name` is used as prefix to the temporary directory name.
      # The directory will be created if it doesn't exist.
      sig { params(name: T.nilable(String)).returns(T.attached_class) }
      def mktmp!(name = nil)
        new(::Dir.mktmpdir(name))
      end
    end

    # The absolute path to the directory this context is about
    sig { returns(String) }
    attr_reader :absolute_path

    # Create a new context about `absolute_path`
    #
    # The directory will not be created if it doesn't exist.
    # Call `#make!` to create it.
    sig { params(absolute_path: String).void }
    def initialize(absolute_path)
      @absolute_path = T.let(::File.expand_path(absolute_path), String)
    end
  end
end
