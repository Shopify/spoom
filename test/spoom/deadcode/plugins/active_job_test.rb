# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ActiveJobTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_active_job_application_job_class
          @project.write!("app/jobs/application_job.rb", <<~RB)
            class ApplicationJob; end
          RB

          index = index_with_plugins
          assert_ignored(index, "ApplicationJob")
        end

        def test_ignore_active_job_methods_based_on_class_name
          @project.write!("foo.rb", <<~RB)
            class Foo
              def build_enumerator; end
              def each_iteration; end
              def perform; end
            end
          RB

          @project.write!("app/jobs/foo.rb", <<~RB)
            class FooJob
              def build_enumerator; end
              def each_iteration; end
              def perform; end
            end
          RB

          assert_equal(
            [
              "app/jobs/foo.rb:2:2-2:27",
              "app/jobs/foo.rb:3:2-3:25",
              "app/jobs/foo.rb:4:2-4:18",
              "foo.rb:2:2-2:27",
              "foo.rb:3:2-3:25",
              "foo.rb:4:2-4:18",
            ],
            ignored_locations(index_with_plugins).map(&:to_s).sort,
          )
        end

        private

        sig { returns(Deadcode::Index) }
        def index_with_plugins
          deadcode_index(plugins: [Plugins::ActiveJob.new])
        end

        sig { params(index: Deadcode::Index).returns(T::Array[Location]) }
        def ignored_locations(index)
          index.all_definitions.select(&:method?).select(&:ignored?).map(&:location)
        end
      end
    end
  end
end
