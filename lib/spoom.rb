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
    const :err, String, default: ""
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
    method = capture_err ? "popen2e" : "popen2"
    Open3.send(method, [cmd, *arg].join(" "), chdir: path) do |_, stdout, thread|
      status = T.cast(thread.value, Process::Status)
      ExecResult.new(out: stdout.read, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
    end
  end
end

require "spoom/colors"
require "spoom/sorbet"
require "spoom/cli"
require "spoom/version"
