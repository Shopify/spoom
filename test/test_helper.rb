# typed: strict
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "minitest/mock"
require "spoom"
require "test_project"

module Spoom
  module TestHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Minitest::Test }

    sig { params(name: T.nilable(String)).returns(TestProject) }
    def new_project(name = nil)
      project = TestProject.mktmp!(name || self.name)
      project.write_gemfile!(spoom_gemfile)
      project.write_sorbet_config!(".")
      project.bundle("config set --local path $GEM_HOME")
      project
    end

    # Default Gemfile contents requiring only Spoom
    sig { returns(String) }
    def spoom_gemfile
      <<~GEMFILE
        source("https://rubygems.org")

        gemspec name: "spoom", path: "#{SPOOM_PATH}"
        gem "sorbet-static-and-runtime", "#{Sorbet::GEM_VERSION}"
      GEMFILE
    end

    # Replace all sorbet-like version "0.5.5888" in `test` by "X.X.XXXX"
    sig { params(text: String).returns(String) }
    def censor_sorbet_version(text)
      text.gsub(/\d\.\d\.\d{4,5}/, "X.X.XXXX")
    end
  end
end

require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new(color: true))
