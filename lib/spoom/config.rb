# typed: true
# frozen_string_literal: true

require 'pathname'

module Spoom
  module Config
    SORBET_CONFIG = "sorbet/config"
    SORBET_GEM_PATH = Gem::Specification.find_by_name("sorbet-static").full_gem_path
    SORBET_PATH = (Pathname.new(SORBET_GEM_PATH) / "libexec" / "sorbet").to_s
    SPOOM_PATH = (Pathname.new(__FILE__) / ".." / ".." / "..").to_s
  end
end
