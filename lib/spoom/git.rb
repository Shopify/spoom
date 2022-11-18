# typed: strict
# frozen_string_literal: true

require "time"

module Spoom
  # Execute git commands
  module Git
    class Commit < T::Struct
      extend T::Sig

      const :sha, String
      const :time, Time

      sig { returns(Integer) }
      def timestamp
        time.to_i
      end
    end

    class << self
      extend T::Sig

      # Execute a `command`
      sig { params(command: String, arg: String, path: String).returns(ExecResult) }
      def exec(command, *arg, path: ".")
        return ExecResult.new(
          out: "",
          err: "Error: `#{path}` is not a directory.",
          status: false,
          exit_code: 1,
        ) unless File.directory?(path)

        T.unsafe(Open3).popen3(command, *arg, chdir: path) do |_, stdout, stderr, thread|
          status = T.cast(thread.value, Process::Status)
          ExecResult.new(
            out: stdout.read,
            err: stderr.read,
            status: T.must(status.success?),
            exit_code: T.must(status.exitstatus),
          )
        end
      end

      # Git commands

      sig { params(arg: String, path: String).returns(ExecResult) }
      def checkout(*arg, path: ".")
        exec("git checkout -q #{arg.join(" ")}", path: path)
      end

      sig { params(arg: String, path: String).returns(ExecResult) }
      def diff(*arg, path: ".")
        exec("git diff #{arg.join(" ")}", path: path)
      end

      sig { params(arg: String, path: String).returns(ExecResult) }
      def log(*arg, path: ".")
        exec("git log #{arg.join(" ")}", path: path)
      end

      sig { params(arg: String, path: String).returns(ExecResult) }
      def rev_parse(*arg, path: ".")
        exec("git rev-parse --short #{arg.join(" ")}", path: path)
      end

      sig { params(arg: String, path: String).returns(ExecResult) }
      def show(*arg, path: ".")
        exec("git show #{arg.join(" ")}", path: path)
      end

      sig { params(path: String).returns(T.nilable(String)) }
      def current_branch(path: ".")
        result = exec("git branch --show-current", path: path)
        return nil unless result.status

        result.out.strip
      end

      # Utils

      # Get the commit epoch timestamp for a `sha`
      sig { params(sha: String, path: String).returns(T.nilable(Integer)) }
      def commit_timestamp(sha, path: ".")
        result = show("--no-notes --no-patch --pretty=%at #{sha}", path: path)
        return nil unless result.status

        result.out.strip.to_i
      end

      # Get the commit Time for a `sha`
      sig { params(sha: String, path: String).returns(T.nilable(Time)) }
      def commit_time(sha, path: ".")
        timestamp = commit_timestamp(sha, path: path)
        return nil unless timestamp

        epoch_to_time(timestamp.to_s)
      end

      # Get the last commit in the currently checked out branch
      sig { params(path: String).returns(T.nilable(Commit)) }
      def last_commit(path: ".")
        result = log("HEAD --format='%h %at' -1", path: path)
        return nil unless result.status

        out = result.out.strip
        return nil if out.empty?

        parse_commit(out)
      end

      # Translate a git epoch timestamp into a Time
      sig { params(timestamp: String).returns(Time) }
      def epoch_to_time(timestamp)
        Time.strptime(timestamp, "%s")
      end

      # Is there uncommited changes in `path`?
      sig { params(path: String).returns(T::Boolean) }
      def workdir_clean?(path: ".")
        diff("HEAD", path: path).out.empty?
      end

      # Get the commit introducing the `sorbet/config` file
      sig { params(path: String).returns(T.nilable(Commit)) }
      def sorbet_intro_commit(path: ".")
        result = log("--diff-filter=A --format='%h %at' -1 -- sorbet/config", path: path)
        return nil unless result.status

        out = result.out.strip
        return nil if out.empty?

        parse_commit(out)
      end

      # Get the commit removing the `sorbet/config` file
      sig { params(path: String).returns(T.nilable(Commit)) }
      def sorbet_removal_commit(path: ".")
        result = log("--diff-filter=D --format='%h %at' -1 -- sorbet/config", path: path)
        return nil unless result.status

        out = result.out.strip
        return nil if out.empty?

        parse_commit(out)
      end

      # Parse a line formated as `%h %at` into a `Commit`
      sig { params(string: String).returns(T.nilable(Commit)) }
      def parse_commit(string)
        sha, epoch = string.split(" ", 2)
        return nil unless sha && epoch

        Commit.new(sha: sha, time: epoch_to_time(epoch))
      end
    end
  end
end
