# typed: strict
# frozen_string_literal: true

module Spoom
  class Context
    # Bundle features for a context
    module Bundle
      extend T::Sig
      extend T::Helpers

      requires_ancestor { Context }

      # Read the `contents` of the Gemfile in this context directory
      sig { returns(T.nilable(String)) }
      def read_gemfile
        read("Gemfile")
      end

      # Set the `contents` of the Gemfile in this context directory
      sig { params(contents: String, append: T::Boolean).void }
      def write_gemfile!(contents, append: false)
        write!("Gemfile", contents, append: append)
      end

      # Run a command with `bundle` in this context directory
      sig { params(command: String, version: T.nilable(String)).returns(ExecResult) }
      def bundle(command, version: nil)
        command = "_#{version}_ #{command}" if version
        exec("bundle #{command}")
      end

      # Run `bundle install` in this context directory
      sig { params(version: T.nilable(String)).returns(ExecResult) }
      def bundle_install!(version: nil)
        bundle("install", version: version)
      end

      # Run a command `bundle exec` in this context directory
      sig { params(command: String, version: T.nilable(String)).returns(ExecResult) }
      def bundle_exec(command, version: nil)
        bundle("exec #{command}", version: version)
      end
    end
  end
end
