# typed: strict
# frozen_string_literal: true

require "test_helper"

module Spoom
  class TestWithProject < Minitest::Test
    extend T::Sig
    extend T::Helpers
    include TestHelper

    abstract!

    sig { returns(TestProject) }
    attr_reader :project

    sig { params(args: T.untyped).void }
    def initialize(*args)
      super
      @project = T.let(new_project, TestProject)
    end

    sig { void }
    def teardown
      @project.destroy!
    end
  end
end
