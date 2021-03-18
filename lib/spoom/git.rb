# typed: strict
# frozen_string_literal: true

require "time"

module Spoom
  # Execute git commands
  module Git
    extend T::Sig

    # Execute a `command`
    sig { params(command: String, arg: String, path: String).returns([String, String, T::Boolean]) }
    def self.exec(command, *arg, path: '.')
      return "", "Error: `#{path}` is not a directory.", false unless File.directory?(path)
      opts = {}
      opts[:chdir] = path
      i, o, e, s = Open3.popen3(*T.unsafe([command, *T.unsafe(arg), opts]))
      out = o.read.to_s
      o.close
      err = e.read.to_s
      e.close
      i.close
      [out, err, T.cast(s.value, Process::Status).success?]
    end

    # Git commands

    sig { params(arg: String, path: String).returns([String, String, T::Boolean]) }
    def self.checkout(*arg, path: ".")
      exec("git checkout -q #{arg.join(' ')}", path: path)
    end

    sig { params(arg: String, path: String).returns([String, String, T::Boolean]) }
    def self.diff(*arg, path: ".")
      exec("git diff #{arg.join(' ')}", path: path)
    end

    sig { params(arg: String, path: String).returns([String, String, T::Boolean]) }
    def self.log(*arg, path: ".")
      exec("git log #{arg.join(' ')}", path: path)
    end

    sig { params(arg: String, path: String).returns([String, String, T::Boolean]) }
    def self.rev_parse(*arg, path: ".")
      exec("git rev-parse --short #{arg.join(' ')}", path: path)
    end

    sig { params(arg: String, path: String).returns([String, String, T::Boolean]) }
    def self.show(*arg, path: ".")
      exec("git show #{arg.join(' ')}", path: path)
    end

    # Utils

    # Get the commit epoch timestamp for a `sha`
    sig { params(sha: String, path: String).returns(T.nilable(Integer)) }
    def self.commit_timestamp(sha, path: ".")
      out, _, status = show("--no-notes --no-patch --pretty=%at #{sha}", path: path)
      return nil unless status
      out.strip.to_i
    end

    # Get the commit Time for a `sha`
    sig { params(sha: String, path: String).returns(T.nilable(Time)) }
    def self.commit_time(sha, path: ".")
      timestamp = commit_timestamp(sha, path: path)
      return nil unless timestamp
      epoch_to_time(timestamp.to_s)
    end

    # Get the last commit sha
    sig { params(path: String).returns(T.nilable(String)) }
    def self.last_commit(path: ".")
      out, _, status = rev_parse("HEAD", path: path)
      return nil unless status
      out.strip
    end

    # Translate a git epoch timestamp into a Time
    sig { params(timestamp: String).returns(Time) }
    def self.epoch_to_time(timestamp)
      Time.strptime(timestamp, "%s")
    end

    # Is there uncommited changes in `path`?
    sig { params(path: String).returns(T::Boolean) }
    def self.workdir_clean?(path: ".")
      diff("HEAD", path: path).first.empty?
    end

    # Get the hash of the commit introducing the `sorbet/config` file
    sig { params(path: String).returns(T.nilable(String)) }
    def self.sorbet_intro_commit(path: ".")
      res, _, status = Spoom::Git.log("--diff-filter=A --format='%h' -1 -- sorbet/config", path: path)
      return nil unless status
      res.strip
    end
  end
end
