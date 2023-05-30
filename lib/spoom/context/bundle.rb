# typed: strict
# frozen_string_literal: true

module Spoom
  class Context
    # Bundle features for a context
    module Bundle
      extend T::Sig
      extend T::Helpers

      requires_ancestor { Context }

      # Read the contents of the Gemfile in this context directory
      sig { returns(T.nilable(String)) }
      def read_gemfile
        read("Gemfile")
      end

      # Read the contents of the Gemfile.lock in this context directory
      sig { returns(T.nilable(String)) }
      def read_gemfile_lock
        read("Gemfile.lock")
      end

      # Set the `contents` of the Gemfile in this context directory
      sig { params(contents: String, append: T::Boolean).void }
      def write_gemfile!(contents, append: false)
        write!("Gemfile", contents, append: append)
      end

      # Run a command with `bundle` in this context directory
      sig { params(command: String, version: T.nilable(String), capture_err: T::Boolean).returns(ExecResult) }
      def bundle(command, version: nil, capture_err: true)
        command = "_#{version}_ #{command}" if version
        exec("bundle #{command}", capture_err: capture_err)
      end

      # Run `bundle install` in this context directory
      sig { params(version: T.nilable(String), capture_err: T::Boolean).returns(ExecResult) }
      def bundle_install!(version: nil, capture_err: true)
        bundle("install", version: version, capture_err: capture_err)
      end

      # Run a command `bundle exec` in this context directory
      sig { params(command: String, version: T.nilable(String), capture_err: T::Boolean).returns(ExecResult) }
      def bundle_exec(command, version: nil, capture_err: true)
        bundle("exec #{command}", version: version, capture_err: capture_err)
      end

      sig { returns(T::Hash[String, Bundler::LazySpecification]) }
      def gemfile_lock_specs
        return {} unless file?("Gemfile.lock")

        parser = Bundler::LockfileParser.new(read_gemfile_lock)
        parser.specs.map { |spec| [spec.name, spec] }.to_h
      end

      # Get `gem` version from the `Gemfile.lock` content
      #
      # Returns `nil` if `gem` cannot be found in the Gemfile.
      sig { params(gem: String).returns(T.nilable(String)) }
      def gem_version_from_gemfile_lock(gem)
        gemfile_lock_specs[gem]&.version&.to_s
      end
    end
  end
end
