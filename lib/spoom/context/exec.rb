# typed: strict
# frozen_string_literal: true

require "shellwords"

module Spoom
  class ExecResult < T::Struct
    const :out, String
    const :err, T.nilable(String)
    const :status, T::Boolean
    const :exit_code, Integer

    #: -> String
    def to_s
      <<~STR
        ########## STDOUT ##########
        #{out.empty? ? "<empty>" : out}
        ########## STDERR ##########
        #{err&.empty? ? "<empty>" : err}
        ########## STATUS: #{status} ##########
      STR
    end
  end

  class Context
    # Execution features for a context
    # @requires_ancestor: Context
    module Exec
      # Run a command in this context directory
      #: (String command, ?capture_err: bool) -> ExecResult
      def exec(command, capture_err: true)
        Bundler.with_unbundled_env do
          opts = { chdir: absolute_path } #: Hash[Symbol, untyped]

          # When Ruby is wrapped in another dev environment (e.g. Nix), that environment might set
          # env variables that cause Sorbet (or other tools) to link to incorrect versions of
          # dependencies.
          #
          # In the case of Sorbet, this can lead to corrupted JSON output.
          #
          # Executing the command directly through the shell bypasses any Ruby wrappers and
          # ensures that we are using the versions of tools that are default on the system.
          command_with_shell = "/bin/sh -c #{command.shellescape}"

          if capture_err
            out, err, status = Open3.capture3(command_with_shell, opts)
            ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
          else
            out, status = Open3.capture2(command_with_shell, opts)
            ExecResult.new(out: out, err: nil, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
          end
        end
      end
    end
  end
end
