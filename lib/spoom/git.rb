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
