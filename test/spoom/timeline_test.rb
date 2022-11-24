# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Sorbet
    class TimelineTest < TestWithProject
      def setup
        @project.git_init!
        @project.exec("git config user.name 'spoom-tests'")
        @project.exec("git config user.email 'spoom@shopify.com'")
        @project.commit!("commit 1", time: Time.parse("2010-01-02 03:04:05"))
        @project.write!("file2", "")
        @project.commit!("commit 2", time: Time.parse("2010-04-01 03:04:05"))
        @project.write!("file3", "")
        @project.commit!("commit 3", time: Time.parse("2010-06-30 03:04:05"))
        @project.write!("file4", "")
        @project.commit!("commit 4", time: Time.parse("2011-01-02 03:04:05"))
      end

      def test_timeline_months
        from = Time.parse("2010-01-02 03:04:05")
        to = Time.parse("2010-03-02 03:04:05")
        timeline = Spoom::Timeline.new(from, to)
        assert_equal(["2010-01", "2010-02", "2010-03"], timeline.months.map { |d| d.strftime("%Y-%m") })
      end

      def test_timeline_commits_for_dates
        timeline = Spoom::Timeline.new(
          Time.parse("2010-01-01 00:00:00"),
          Time.parse("2020-01-01 00:00:00"),
          path: @project.absolute_path,
        )

        dates = [
          Time.parse("2000-01-01 00:00:00"),
          Time.parse("2000-02-01 00:00:00"),
        ]
        assert_equal(0, timeline.commits_for_dates(dates).size)

        dates << Time.parse("2010-01-01 00:00:00")
        assert_equal(1, timeline.commits_for_dates(dates).size)

        dates << Time.parse("2010-04-01 00:00:00")
        assert_equal(2, timeline.commits_for_dates(dates).size)

        dates << Time.parse("2010-05-01 00:00:00")
        assert_equal(2, timeline.commits_for_dates(dates).size)

        dates << Time.parse("2010-06-01 00:00:00")
        assert_equal(3, timeline.commits_for_dates(dates).size)

        dates << Time.parse("2011-01-01 00:00:00")
        assert_equal(4, timeline.commits_for_dates(dates).size)
      end

      def test_timeline_ticks
        timeline = Spoom::Timeline.new(
          Time.parse("2010-01-01 00:00:00"),
          Time.parse("2020-01-01 00:00:00"),
          path: @project.absolute_path,
        )
        assert_equal(4, timeline.ticks.size)
      end
    end
  end
end
