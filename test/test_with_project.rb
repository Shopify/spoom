# typed: strict
# frozen_string_literal: true

require "test_helper"

module Spoom
  class TestWithProject < Minitest::Test
    extend T::Helpers
    include TestHelper

    abstract!

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
