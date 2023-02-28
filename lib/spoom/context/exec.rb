# typed: strict
# frozen_string_literal: true

module Spoom
  class Context
    # Execution features for a context
    module Exec
      extend T::Sig
      extend T::Helpers

      requires_ancestor { Context }

      # Run a command in this context directory
      sig { params(command: String, capture_err: T::Boolean).returns(ExecResult) }
      def exec(command, capture_err: true)
        Bundler.with_unbundled_env do
          opts = T.let({ chdir: absolute_path }, T::Hash[Symbol, T.untyped])

          if capture_err
            out, err, status = Open3.capture3(command, opts)
            ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
          else
            out, status = Open3.capture2(command, opts)
            ExecResult.new(out: out, err: nil, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
          end
        end
      end
    end
  end
end
