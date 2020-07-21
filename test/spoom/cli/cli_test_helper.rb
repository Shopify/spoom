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
      PROJECT_PATH = "test/support/project"
      SORBET_CONFIG_PATH = (Pathname.new(PROJECT_PATH) / Spoom::Config::SORBET_CONFIG).to_s

      def project_path
        PROJECT_PATH
      end

      def sorbet_config_path
        SORBET_CONFIG_PATH
      end

      def set_sorbet_config(config) # rubocop:disable Naming/AccessorMethodName
        FileUtils.mkdir_p(File.dirname(sorbet_config_path))
        File.write(sorbet_config_path, config)
      end

      def clean_sorbet_config
        File.delete(sorbet_config_path) if File.exist?(sorbet_config_path)
      end

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

      def run_cli(work_dir, command, args = [], run_opts = {})
        Bundler.with_clean_env do
          run_opts[:chdir] = work_dir
          Open3.popen3(["bundle", "exec", "spoom", command, *args].join(' '), run_opts) do |_, o, e, s|
            out = o.read
            err = e.read
            return out, err, s.value
          end
        end
      end
    end
  end
end
