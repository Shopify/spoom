# typed: true
# frozen_string_literal: true

require 'pathname'

module Spoom
  module Config
    SPOOM_PATH = (Pathname.new(__FILE__) / ".." / ".." / "..").to_s
  end
end
