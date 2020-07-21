# typed: true
# frozen_string_literal: true

require "fileutils"

require_relative "../../test_helper"

module Spoom
  module Cli
    module TestHelper
      extend T::Sig
      include Spoom::TestHelper

      TEST_PROJECTS_PATH = "test/support"

      # Run `bundle install` inside `project_name` and raises if the process didn't finish correctly.
      sig { params(project_name: String).void }
      def install_sorbet(project_name)
        Bundler.with_clean_env do
          opts = {}
          opts[:chdir] = "#{TEST_PROJECTS_PATH}/#{project_name}"
          Open3.popen2e("bundle", "install", "--quiet", opts) do |_, o, t|
            status = T.cast(t.value, Process::Status)
            Kernel.raise "error during `bundle install` (#{o.read})" unless status.success?
          end
        end
      end

      # Run `bundle exec spoom` inside `project_name` and returns the out, err and status from the process.
      sig { params(project_name: String, args: String).returns([T.nilable(String), T.nilable(String), T::Boolean]) }
      def run_cli(project_name, *args)
        Bundler.with_clean_env do
          opts = {}
          opts[:chdir] = "#{TEST_PROJECTS_PATH}/#{project_name}"
          Open3.popen3(["bundle", "exec", "spoom", *args].join(' '), opts) do |_, o, e, t|
            status = T.cast(t.value, Process::Status)
            return o.read, e.read, status.success?
          end
        end
      end

      # Set `config` as content of `sorbet/config` for `project_name`.
      # Passing `nil` will remove the `sorbet/config` file.
      sig { params(project_name: String, config: T.nilable(String)).void }
      def use_sorbet_config(project_name, config)
        path = "#{TEST_PROJECTS_PATH}/#{project_name}/#{Spoom::Config::SORBET_CONFIG}"
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.rm_rf(path)
        File.write(path, config) if config
      end
    end
  end
end
