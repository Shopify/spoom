# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "pathname"
require "saturn"

module Spoom
  SPOOM_PATH = (Pathname.new(__FILE__) / ".." / "..").to_s #: String

  class Error < StandardError; end
end

require "spoom/file_collector"
require "spoom/context"
require "spoom/colors"
require "spoom/poset"
require "spoom/model"
require "spoom/source"
require "spoom/deadcode"
require "spoom/rbs"
require "spoom/counters"
require "spoom/sorbet"
require "spoom/cli"
require "spoom/version"
