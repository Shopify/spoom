# typed: strict
# frozen_string_literal: true

require_relative "git"

module Spoom
  class Timeline
    extend T::Sig

    sig { params(from: Time, to: Time, path: String).void }
    def initialize(from, to, path: ".")
      @from = from
      @to = to
      @path = path
    end

    # Return one commit for each month between `from` and `to`
    sig { returns(T::Array[String]) }
    def ticks
      commits_for_dates(months)
    end

    # Return all months between `from` and `to`
    sig { returns(T::Array[Time]) }
    def months
      d = Date.new(@from.year, @from.month, 1)
      to = Date.new(@to.year, @to.month, 1)
      res = [d.to_time]
      while d < to
        d = d.next_month
        res << d.to_time
      end
      res
    end

    # Return one commit for each date in `dates`
    sig { params(dates: T::Array[Time]).returns(T::Array[String]) }
    def commits_for_dates(dates)
      dates.map do |t|
        result = Spoom::Git.log(
          "--since='#{t}'",
          "--until='#{t.to_date.next_month}'",
          "--format='format:%h'",
          "--author-date-order",
          "-1",
          path: @path,
        )
        next if result.out.empty?

        result.out
      end.compact.uniq
    end
  end
end
