# typed: strict
# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"

require_relative "context/exec"
require_relative "context/file_system"

module Spoom
  # An abstraction to a Ruby project context
  #
  # A context maps to a directory in the file system.
  # It is used to manipulate files and run commands in the context of this directory.
  class Context
    extend T::Sig

    include Exec
    include FileSystem

    # The absolute path to the directory this context is about
    sig { returns(String) }
    attr_reader :absolute_path

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

    # Create a new context about `absolute_path`
    #
    # The directory will not be created if it doesn't exist.
    # Call `#make!` to create it.
    sig { params(absolute_path: String).void }
    def initialize(absolute_path)
      @absolute_path = T.let(::File.expand_path(absolute_path), String)
    end

    # Bundle

    # Read the `contents` of the Gemfile in this context directory
    sig { returns(T.nilable(String)) }
    def read_gemfile
      read("Gemfile")
    end

    # Set the `contents` of the Gemfile in this context directory
    sig { params(contents: String, append: T::Boolean).void }
    def write_gemfile!(contents, append: false)
      write!("Gemfile", contents, append: append)
    end

    # Run a command with `bundle` in this context directory
    sig { params(command: String, version: T.nilable(String)).returns(ExecResult) }
    def bundle(command, version: nil)
      command = "_#{version}_ #{command}" if version
      exec("bundle #{command}")
    end

    # Run `bundle install` in this context directory
    sig { params(version: T.nilable(String)).returns(ExecResult) }
    def bundle_install!(version: nil)
      bundle("install", version: version)
    end

    # Run a command `bundle exec` in this context directory
    sig { params(command: String, version: T.nilable(String)).returns(ExecResult) }
    def bundle_exec(command, version: nil)
      bundle("exec #{command}", version: version)
    end

    # Git

    # Run a command prefixed by `git` in this context directory
    sig { params(command: String).returns(ExecResult) }
    def git(command)
      exec("git #{command}")
    end

    # Run `git init` in this context directory
    #
    # Warning: passing a branch will run `git init -b <branch>` which is only available in git 2.28+.
    # In older versions, use `git_init!` followed by `git("checkout -b <branch>")`.
    sig { params(branch: T.nilable(String)).returns(ExecResult) }
    def git_init!(branch: nil)
      if branch
        git("init -b #{branch}")
      else
        git("init")
      end
    end

    # Run `git checkout` in this context directory
    sig { params(ref: String).returns(ExecResult) }
    def git_checkout!(ref: "main")
      git("checkout #{ref}")
    end

    # Get the current git branch in this context directory
    sig { returns(T.nilable(String)) }
    def git_current_branch
      Spoom::Git.current_branch(path: @absolute_path)
    end

    # Get the last commit in the currently checked out branch
    sig { params(short_sha: T::Boolean).returns(T.nilable(Git::Commit)) }
    def git_last_commit(short_sha: true)
      Spoom::Git.last_commit(path: @absolute_path, short_sha: short_sha)
    end

    # Sorbet

    # Run `bundle exec srb` in this context directory
    sig { params(command: String).returns(ExecResult) }
    def srb(command)
      bundle_exec("srb #{command}")
    end

    # Read the contents of `sorbet/config` in this context directory
    sig { returns(String) }
    def read_sorbet_config
      read(Spoom::Sorbet::CONFIG_PATH)
    end

    # Set the `contents` of `sorbet/config` in this context directory
    sig { params(contents: String, append: T::Boolean).void }
    def write_sorbet_config!(contents, append: false)
      write!(Spoom::Sorbet::CONFIG_PATH, contents, append: append)
    end

    # Read the strictness sigil from the file at `relative_path` (returns `nil` if no sigil)
    sig { params(relative_path: String).returns(T.nilable(String)) }
    def read_file_strictness(relative_path)
      Spoom::Sorbet::Sigils.file_strictness(absolute_path_to(relative_path))
    end
  end
end
