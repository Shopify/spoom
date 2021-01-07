# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Spoom
  extend T::Sig

  SPOOM_PATH = (Pathname.new(__FILE__) / ".." / "..").to_s

  class Error < StandardError; end

  sig do
    params(
      cmd: String,
      arg: String,
      path: String,
      capture_err: T::Boolean
    ).returns([String, T::Boolean])
  end
  def self.exec(cmd, *arg, path: '.', capture_err: false)
    method = capture_err ? "popen2e" : "popen2"
    Open3.send(method, [cmd, *arg].join(" "), chdir: path) do |_, o, t|
      [o.read, T.cast(t.value, Process::Status).success?]
    end
  end
end

require "spoom/sorbet"
require "spoom/cli"
require "spoom/version"
