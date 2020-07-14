# typed: true
# frozen_string_literal: true

require "spoom/sorbet/config"

require "open3"

module Spoom
  # All Sorbet-related services.
  module Sorbet
    # Run `bundle install` so Sorbet is installed after.
    #
    # `work_dir` can be changed to run bundle in another directory than `.`.
    def self.bundle_install(work_dir = '.', opts = {})
      Bundler.with_clean_env do
        opts[:chdir] = File.expand_path(work_dir)
        Open3.popen3("bundle", "install", "--quiet", opts) do |_, out, err, thread|
          status = T.cast(thread.value, Process::Status)
          raise BundleInstallError.new("error during `bundle install`", out, err) unless status.success?
          return out, err, status
        end
      end
    end

    class BundleInstallError < Spoom::Error
      attr_reader :out, :err

      def initialize(message, out, err)
        super(message)
        @out = out
        @err = err
      end
    end
  end
end
