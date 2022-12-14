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

    sig { params(message: String, time: Time).void }
    def commit!(message = "message", time: Time.now.utc)
      exec("git add --all")
      exec("GIT_COMMITTER_DATE=\"#{time}\" git -c commit.gpgsign=false commit -m '#{message}' --date '#{time}'")
    end

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
