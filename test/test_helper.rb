# typed: true
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "spoom"

module Spoom
  module TestHelper
    # Run an action before all tests only once
    def before_all
      unless @before_all
        yield
        @before_all = true
      end
    end
  end
end

require "minitest/autorun"
