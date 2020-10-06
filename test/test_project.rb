# typed: strict
# frozen_string_literal: true

require "fileutils"
require "open3"
require "pathname"

require_relative "../lib/spoom/git"

module Spoom
  class TestProject
    extend T::Sig

    # The absolute path to this test project
    sig { returns(String) }
    attr_reader :path

    # Create a new test project at `path`
    sig { params(path: String).void }
    def initialize(path)
      @path = path
      FileUtils.rm_rf(@path)
      FileUtils.mkdir_p(@path)
    end

    # Content

    # Set the content of the Gemfile in this project
    sig { params(content: String).void }
    def gemfile(content)
      write("Gemfile", content)
    end

    # Set the content of `sorbet/config` in this project
    sig { params(content: String).void }
    def sorbet_config(content)
      write("sorbet/config", content)
    end

    # Write `content` in the file at `rel_path`
    sig { params(rel_path: String, content: String).void }
    def write(rel_path, content = "")
      path = absolute_path(rel_path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    # Remove `rel_path`
    sig { params(rel_path: String).void }
    def remove(rel_path)
      FileUtils.rm_rf(absolute_path(rel_path))
    end

    # Actions

    # Run `git init` in this project
    sig { void }
    def git_init
      Spoom::Git.exec("git init -q", path: path)
      Spoom::Git.exec("git config user.name 'spoom-tests'", path: path)
      Spoom::Git.exec("git config user.email 'spoom@shopify.com'", path: path)
    end

    # Commit all new changes in this project
    sig { params(message: String, date: Time).void }
    def commit(message = "message", date: Time.now.utc)
      Spoom::Git.exec("git add --all", path: path)
      Spoom::Git.exec("GIT_COMMITTER_DATE=\"#{date}\" git commit -m '#{message}' --date '#{date}'", path: path)
    end

    # Run a command with `bundle exec` in this project
    sig { params(cmd: String, args: String).returns([T.nilable(String), T.nilable(String), T::Boolean]) }
    def bundle_exec(cmd, *args)
      opts = {}
      opts[:chdir] = path
      out, err, status = Open3.capture3(["bundle", "exec", cmd, *args].join(' '), opts)
      [out, err, status.success?]
    end

    # Delete this project and its content
    sig { void }
    def destroy
      FileUtils.rm_rf(path)
    end

    private

    # Create an absolute path from `self.path` and `rel_path`
    sig { params(rel_path: String).returns(String) }
    def absolute_path(rel_path)
      (Pathname.new(path) / rel_path).to_s
    end
  end
end
