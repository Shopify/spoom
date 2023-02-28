# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Git
    class GitTest < TestWithProject
      def setup
        @project.git_init!
        @project.exec("git config user.name 'spoom-tests'")
        @project.exec("git config user.email 'spoom@shopify.com'")
      end

      def test_exec_with_unexisting_path
        e = assert_raises(Errno::ENOENT) do
          Spoom.exec("git ls", path: "/path/not/found")
        end
        assert_equal("No such file or directory - /path/not/found", e.message)
      end

      def test_git_show
        @project.write!("file")
        @project.commit!(time: Time.parse("1987-02-05 09:00:00"))
        assert_match(/Thu Feb 5 09:00:00 1987/, Spoom::Git.show(path: @project.absolute_path).out)
      end
    end
  end
end
