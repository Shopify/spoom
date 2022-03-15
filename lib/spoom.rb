# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "pathname"

module Spoom
  extend T::Sig

  SPOOM_PATH = T.let((Pathname.new(__FILE__) / ".." / "..").to_s, String)

  class Error < StandardError; end

  class ExecResult < T::Struct
    const :out, String
    const :err, String
    const :status, T::Boolean
    const :exit_code, Integer
  end

  sig do
    params(
      cmd: String,
      arg: String,
      path: String,
      capture_err: T::Boolean
    ).returns(ExecResult)
  end
  def self.exec(cmd, *arg, path: '.', capture_err: false)
    if capture_err
      stdout, stderr, status = T.unsafe(Open3).capture3([cmd, *arg].join(" "), chdir: path)
      ExecResult.new(
        out: stdout,
        err: stderr,
        status: status.success?,
        exit_code: status.exitstatus
      )
    else
      stdout, status = T.unsafe(Open3).capture2([cmd, *arg].join(" "), chdir: path)
      ExecResult.new(
        out: stdout,
        err: "",
        status: status.success?,
        exit_code: status.exitstatus
      )
    end
  end
end

require "spoom/colors"
require "spoom/sorbet"
require "spoom/cli"
require "spoom/version"
