# typed: strict
# frozen_string_literal: true

require "test_helper"

module Spoom
  # @abstract
  class TestWithProject < Minitest::Test
    include TestHelper

    #: TestProject
    attr_reader :project

    #: (*untyped args) -> void
    def initialize(*args)
      super
      @project = new_project #: TestProject
    end

    #: -> void
    def teardown
      @project.destroy!
    end
  end
end
