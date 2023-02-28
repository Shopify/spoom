# typed: strict
# frozen_string_literal: true

module Spoom
  class Context
    # Git features for a context
    module Git
      extend T::Sig
      extend T::Helpers

      requires_ancestor { Context }

      # Run a command prefixed by `git` in this context directory
      sig { params(command: String).returns(ExecResult) }
      def git(command)
        exec("git #{command}")
      end

      # Run `git init` in this context directory
      #
      # Warning: passing a branch will run `git init -b <branch>` which is only available in git 2.28+.
      # In older versions, use `git_init!` followed by `git("checkout -b <branch>")`.
      sig { params(branch: T.nilable(String)).returns(ExecResult) }
      def git_init!(branch: nil)
        if branch
          git("init -b #{branch}")
        else
          git("init")
        end
      end

      # Run `git checkout` in this context directory
      sig { params(ref: String).returns(ExecResult) }
      def git_checkout!(ref: "main")
        git("checkout #{ref}")
      end

      # Run `git add . && git commit` in this context directory
      sig { params(message: String, time: Time, allow_empty: T::Boolean).void }
      def git_commit!(message: "message", time: Time.now.utc, allow_empty: false)
        git("add --all")

        args = ["-m '#{message}'", "--date '#{time}'"]
        args << "--allow-empty" if allow_empty

        exec("GIT_COMMITTER_DATE=\"#{time}\" git -c commit.gpgsign=false commit #{args.join(" ")}")
      end

      # Get the current git branch in this context directory
      sig { returns(T.nilable(String)) }
      def git_current_branch
        res = git("branch --show-current")
        return nil unless res.status

        res.out.strip
      end

      # Run `git diff` in this context directory
      sig { params(arg: String).returns(ExecResult) }
      def git_diff(*arg)
        git("diff #{arg.join(" ")}")
      end

      # Get the last commit in the currently checked out branch
      sig { params(short_sha: T::Boolean).returns(T.nilable(Spoom::Git::Commit)) }
      def git_last_commit(short_sha: true)
        Spoom::Git.last_commit(path: absolute_path, short_sha: short_sha)
      end

      sig { params(arg: String).returns(ExecResult) }
      def git_log(*arg)
        git("log #{arg.join(" ")}")
      end
    end
  end
end
