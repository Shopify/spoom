# typed: strict
# frozen_string_literal: true

require "time"

module Spoom
  # Execute git commands
  module Git
    extend T::Sig

    # Execute a `command`
    sig { params(command: String, arg: String, path: String).returns(ExecResult) }
    def self.exec(command, *arg, path: ".")
      return ExecResult.new(
        out: "",
        err: "Error: `#{path}` is not a directory.",
        status: false,
        exit_code: 1
      ) unless File.directory?(path)

      T.unsafe(Open3).popen3(command, *arg, chdir: path) do |_, stdout, stderr, thread|
        status = T.cast(thread.value, Process::Status)
        ExecResult.new(
          out: stdout.read,
          err: stderr.read,
          status: T.must(status.success?),
          exit_code: T.must(status.exitstatus)
        )
      end
    end

    # Git commands

    sig { params(arg: String, path: String).returns(ExecResult) }
    def self.checkout(*arg, path: ".")
      exec("git checkout -q #{arg.join(" ")}", path: path)
    end

    sig { params(arg: String, path: String).returns(ExecResult) }
    def self.diff(*arg, path: ".")
      exec("git diff #{arg.join(" ")}", path: path)
    end

    sig { params(arg: String, path: String).returns(ExecResult) }
    def self.log(*arg, path: ".")
      exec("git log #{arg.join(" ")}", path: path)
    end

    sig { params(arg: String, path: String).returns(ExecResult) }
    def self.rev_parse(*arg, path: ".")
      exec("git rev-parse --short #{arg.join(" ")}", path: path)
    end

    sig { params(arg: String, path: String).returns(ExecResult) }
    def self.show(*arg, path: ".")
      exec("git show #{arg.join(" ")}", path: path)
    end

    sig { params(path: String).returns(T.nilable(String)) }
    def self.current_branch(path: ".")
      result = exec("git branch --show-current", path: path)
      return nil unless result.status

      result.out.strip
    end

    # Utils

    # Get the commit epoch timestamp for a `sha`
    sig { params(sha: String, path: String).returns(T.nilable(Integer)) }
    def self.commit_timestamp(sha, path: ".")
      result = show("--no-notes --no-patch --pretty=%at #{sha}", path: path)
      return nil unless result.status

      result.out.strip.to_i
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
      result = rev_parse("HEAD", path: path)
      return nil unless result.status

      result.out.strip
    end

    # Translate a git epoch timestamp into a Time
    sig { params(timestamp: String).returns(Time) }
    def self.epoch_to_time(timestamp)
      Time.strptime(timestamp, "%s")
    end

    # Is there uncommited changes in `path`?
    sig { params(path: String).returns(T::Boolean) }
    def self.workdir_clean?(path: ".")
      diff("HEAD", path: path).out.empty?
    end

    # Get the hash of the commit introducing the `sorbet/config` file
    sig { params(path: String).returns(T.nilable(String)) }
    def self.sorbet_intro_commit(path: ".")
      result = Spoom::Git.log("--diff-filter=A --format='%h' -1 -- sorbet/config", path: path)
      return nil unless result.status

      out = result.out.strip
      return nil if out.empty?

      out
    end

    # Get the hash of the commit removing the `sorbet/config` file
    sig { params(path: String).returns(T.nilable(String)) }
    def self.sorbet_removal_commit(path: ".")
      result = Spoom::Git.log("--diff-filter=D --format='%h' -1 -- sorbet/config", path: path)
      return nil unless result.status

      out = result.out.strip
      return nil if out.empty?

      out
    end
  end
end
