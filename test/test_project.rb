# typed: strict
# frozen_string_literal: true

module Spoom
  class TestProject < Context
    extend T::Sig
    extend T::Helpers

    sig { params(command: String).returns(ExecResult) }
    def spoom(command)
      bundle_exec("spoom #{command}")
    end

    # Git

    sig { params(name: String).void }
    def create_and_checkout_branch!(name)
      exec("git checkout -b #{name}")
    end

    # Misc

    sig { params(text: String).returns(String) }
    def censor_project_path(text)
      text.gsub(absolute_path, "")
    end
  end
end
