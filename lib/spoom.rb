# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Spoom
  SPOOM_PATH = (Pathname.new(__FILE__) / ".." / "..").to_s

  class Error < StandardError; end
end

require "spoom/sorbet"
require "spoom/cli"
require "spoom/version"
