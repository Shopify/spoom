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

      # Git commands

      sig { params(arg: String, path: String).returns(ExecResult) }
      def show(*arg, path: ".")
        Spoom.exec("git show #{arg.join(" ")}", path: path)
      end

      # Utils

      # Get the last commit in the currently checked out branch
      sig { params(path: String, short_sha: T::Boolean).returns(T.nilable(Commit)) }
      def last_commit(path: ".", short_sha: true)
        result = log("HEAD --format='%#{short_sha ? "h" : "H"} %at' -1", path: path)
        return nil unless result.status

        out = result.out.strip
        return nil if out.empty?

        parse_commit(out)
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

        time = Time.strptime(epoch, "%s")
        Commit.new(sha: sha, time: time)
      end
    end
  end
end
