# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Spoom
  class Error < StandardError; end
end

require "spoom/cli"
require "spoom/config"
require "spoom/sorbet"
require "spoom/version"
