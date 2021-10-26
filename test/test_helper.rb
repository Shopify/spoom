# typed: strict
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "spoom"
require "spoom/test_helpers/project"

module Spoom
  module TestHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Minitest::Test }

    TEST_PROJECTS_PATH = "/tmp/spoom/tests"

    sig { params(name: T.nilable(String)).returns(TestHelpers::Project) }
    def spoom_project(name = nil)
      project = TestHelpers::Project.new("#{TEST_PROJECTS_PATH}/#{name || self.name}")
      project.sorbet_config(".")
      project
    end

    sig { returns(String) }
    def spoom_gemfile
      <<~GEM
        gem("spoom", path: "#{spoom_path}")
      GEM
    end

    sig { returns(String) }
    def spoom_path
      path = File.dirname(__FILE__)   # spoom/test/spoom/
      path = File.dirname(path)       # spoom/test/
      path = File.dirname(path)       # spoom/
      File.expand_path(path)
    end

    # Replace all sorbet-like version "0.5.5888" in `test` by "X.X.XXXX"
    sig { params(text: String).returns(String) }
    def censor_sorbet_version(text)
      text.gsub(/\d\.\d\.\d{4}/, "X.X.XXXX")
    end
  end
end

require "minitest/autorun"
