# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "pathname"

module Spoom
  extend T::Sig

  SPOOM_PATH = T.let((Pathname.new(__FILE__) / ".." / "..").to_s, String)

  class Error < StandardError; end
end

require "spoom/file_collector"
require "spoom/context"
require "spoom/colors"
require "spoom/poset"
require "spoom/model"
require "spoom/deadcode"
require "spoom/sorbet"
require "spoom/cli"
require "spoom/version"
