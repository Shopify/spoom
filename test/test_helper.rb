# typed: strict
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "minitest/mock"
require "spoom"
require "test_project"

module Spoom
  # @requires_ancestor: Minitest::Test
  module TestHelper
    #: (?String? name) -> TestProject
    def new_project(name = nil)
      project = TestProject.mktmp!(name || self.name)
      project.write_gemfile!(spoom_gemfile)
      project.write_sorbet_config!(".")
      project.bundle("config set --local path $GEM_HOME")
      project
    end

    # Default Gemfile contents requiring only Spoom
    #: -> String
    def spoom_gemfile
      Spoom::TestHelper.default_spoom_test_gemfile
    end

    # Replace all sorbet-like version "0.5.5888" in `test` by "X.X.XXXX"
    #: (String text) -> String
    def censor_sorbet_version(text)
      text.gsub(/\d\.\d\.\d{4,5}/, "X.X.XXXX")
    end

    class << self
      #: -> String
      def default_spoom_test_gemfile
        @default_spoom_test_gemfile ||= <<~GEMFILE #: String?
          source("https://rubygems.org")

          gemspec name: "spoom", path: "#{SPOOM_PATH}"

          #{Spoom::BundlerHelper.gem_requirement_from_real_bundle("tapioca")}
          #{Spoom::BundlerHelper.gem_requirement_from_real_bundle("sorbet-static-and-runtime")}
          #{Spoom::BundlerHelper.gem_requirement_from_real_bundle("json")}
        GEMFILE
      end
    end
  end
end

require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new(color: true))
