# typed: strict
# frozen_string_literal: true

require "fileutils"
require "open3"

module Spoom
  # An abstraction to a Ruby project context
  #
  # A context maps to a directory in the file system.
  # It is used to manipulate files and run commands in the context of this directory.
  class Context
    extend T::Sig

    # The absolute path to the directory this context is about
    sig { returns(String) }
    attr_reader :absolute_path

    # Create a new context in the system's temporary directory
    #
    # `name` is used as prefix to the temporary directory name.
    # The directory will be created if it doesn't exist.
    sig { params(name: T.nilable(String)).returns(T.attached_class) }
    def self.mktmp!(name = nil)
      new(::Dir.mktmpdir(name))
    end

    # Create a new context about `absolute_path`
    #
    # The directory will not be created if it doesn't exist.
    # Call `#make!` to create it.
    sig { params(absolute_path: String).void }
    def initialize(absolute_path)
      @absolute_path = T.let(::File.expand_path(absolute_path), String)
    end

    # Returns the absolute path to `relative_path` in the context's directory
    sig { params(relative_path: String).returns(String) }
    def absolute_path_to(relative_path)
      File.join(@absolute_path, relative_path)
    end

    # File System

    # Create the context directory at `absolute_path`
    sig { void }
    def mkdir!
      FileUtils.rm_rf(@absolute_path)
      FileUtils.mkdir_p(@absolute_path)
    end

    # List all files in this context matching `pattern`
    sig { params(pattern: String).returns(T::Array[String]) }
    def glob(pattern = "**/*")
      Dir.glob(absolute_path_to(pattern)).map do |path|
        Pathname.new(path).relative_path_from(@absolute_path).to_s
      end.sort
    end

    # List all files at the top level of this context directory
    sig { returns(T::Array[String]) }
    def list
      glob("*")
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
      FileUtils.rm_rf(@absolute_path)
    end

    # Execution

    # Run a command in this context directory
    sig { params(command: String, capture_err: T::Boolean).returns(ExecResult) }
    def exec(command, capture_err: true)
      Bundler.with_unbundled_env do
        opts = T.let({ chdir: @absolute_path }, T::Hash[Symbol, T.untyped])

        if capture_err
          out, err, status = Open3.capture3(command, opts)
          ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
        else
          out, status = Open3.capture2(command, opts)
          ExecResult.new(out: out, err: "", status: T.must(status.success?), exit_code: T.must(status.exitstatus))
        end
      end
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
    sig { params(branch: String).void }
    def git_init!(branch: "main")
      git("init -q -b #{branch}")
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
