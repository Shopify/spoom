# typed: strict
# frozen_string_literal: true

module Spoom
  class TestProject < Context
    #: (String command) -> ExecResult
    def spoom(command)
      bundle_exec("spoom #{command}")
    end
  end
end
