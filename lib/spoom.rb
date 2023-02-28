# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "pathname"

module Spoom
  extend T::Sig

  SPOOM_PATH = T.let((Pathname.new(__FILE__) / ".." / "..").to_s, String)

  class Error < StandardError; end

  class ExecResult < T::Struct
    extend T::Sig

    const :out, String
    const :err, T.nilable(String)
    const :status, T::Boolean
    const :exit_code, Integer

    sig { returns(String) }
    def to_s
      <<~STR
        ########## STDOUT ##########
        #{out.empty? ? "<empty>" : out}
        ########## STDERR ##########
        #{err&.empty? ? "<empty>" : err}
        ########## STATUS: #{status} ##########
      STR
    end
  end

  class << self
    extend T::Sig

    sig do
      params(
        cmd: String,
        arg: String,
        path: String,
        capture_err: T::Boolean,
      ).returns(ExecResult)
    end
    def exec(cmd, *arg, path: ".", capture_err: false)
      if capture_err
        stdout, stderr, status = T.unsafe(Open3).capture3([cmd, *arg].join(" "), chdir: path)
        ExecResult.new(
          out: stdout,
          err: stderr,
          status: status.success?,
          exit_code: status.exitstatus,
        )
      else
        stdout, status = T.unsafe(Open3).capture2([cmd, *arg].join(" "), chdir: path)
        ExecResult.new(
          out: stdout,
          err: nil,
          status: status.success?,
          exit_code: status.exitstatus,
        )
      end
    end
  end
end

require "spoom/context"
require "spoom/colors"
require "spoom/sorbet"
require "spoom/cli"
require "spoom/version"
