# typed: true
# frozen_string_literal: true

require "test_helper"
require_relative "git_test_helper"
require_relative "../../lib/spoom/timeline.rb"

module Spoom
  module Sorbet
    class TimelineTest < Minitest::Test
      include Spoom::Git::TestHelper

      def test_timeline_months
        from = Time.parse("2010-01-02 03:04:05")
        to = Time.parse("2010-03-02 03:04:05")
        timeline = Spoom::Timeline.new(from, to)
        assert_equal(["2010-01", "2010-02", "2010-03"], timeline.months.map { |d| d.strftime("%Y-%m") })
      end

      def test_timeline_commits_for_dates
        repo = test_repo("test_timeline_commits_for_dates")

        timeline = Spoom::Timeline.new(
          Time.parse("2010-01-01 00:00:00"),
          Time.parse("2020-01-01 00:00:00"),
          path: repo.path
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

        repo.destroy
      end

      def test_timeline_ticks
        repo = test_repo("test_timeline_ticks")

        timeline = Spoom::Timeline.new(
          Time.parse("2010-01-01 00:00:00"),
          Time.parse("2020-01-01 00:00:00"),
          path: repo.path
        )
        assert_equal(4, timeline.ticks.size)
        repo.destroy
      end

      private

      def test_repo(name)
        repo = repo(name)
        repo.write_file("sorbet/config", "")
        repo.commit("commit 1", date: Time.parse("2010-01-02 03:04:05"))
        repo.write_file("file2", "")
        repo.commit("commit 2", date: Time.parse("2010-04-01 03:04:05"))
        repo.write_file("file3", "")
        repo.commit("commit 3", date: Time.parse("2010-06-30 03:04:05"))
        repo.write_file("file4", "")
        repo.commit("commit 4", date: Time.parse("2011-01-02 03:04:05"))
        repo
      end
    end
  end
end
