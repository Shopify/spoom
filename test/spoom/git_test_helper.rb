# typed: strict
# frozen_string_literal: true

require_relative "cli/cli_test_helper"
require_relative "../../lib/spoom/git"

require "fileutils"

module Spoom
  module Git
    module TestHelper
      extend T::Sig

      sig { params(name: String).returns(TestRepo) }
      def repo(name)
        TestRepo.new(name)
      end

      class TestRepo
        extend T::Sig

        sig { returns(String) }
        attr_reader :name, :path

        sig { params(name: String).void }
        def initialize(name)
          @name = name
          @path = T.let("#{Cli::TestHelper::TEST_PROJECTS_PATH}/#{name}", String)
          FileUtils.rm_rf(@path)
          FileUtils.mkdir_p(@path)
          Spoom::Git.exec("git init -q", path: @path)
          Spoom::Git.exec("git config user.name 'spoom-tests'", path: @path)
          Spoom::Git.exec("git config user.email 'spoom@shopify.com'", path: @path)
        end

        sig { params(path: String, content: String).void }
        def write_file(path, content = "")
          full_path = "#{self.path}/#{path}"
          FileUtils.mkdir_p(File.dirname(full_path))
          File.write(full_path, content)
        end

        sig { params(path: String).void }
        def remove_file(path)
          full_path = "#{self.path}/#{path}"
          FileUtils.rm_rf(full_path)
        end

        sig { params(message: String, date: Time).void }
        def commit(message = "message", date: Time.now.utc)
          Spoom::Git.exec("git add --all", path: path)
          Spoom::Git.exec("GIT_COMMITTER_DATE=\"#{date}\" git commit -m '#{message}' --date '#{date}'", path: path)
        end

        sig { void }
        def destroy
          FileUtils.rm_rf(path)
        end
      end
    end
  end
end
