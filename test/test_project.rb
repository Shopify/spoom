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

    sig { params(message: String, date: Time).void }
    def commit!(message = "message", date: Time.now.utc)
      exec("git add --all")
      exec("GIT_COMMITTER_DATE=\"#{date}\" git commit -m '#{message}' --date '#{date}'")
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
