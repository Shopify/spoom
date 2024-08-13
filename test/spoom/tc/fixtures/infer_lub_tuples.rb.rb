# typed: true
class Opus::CIBot::Tasks::NotifySlackBuildComplete
  extend T::Sig

  def initialize()
    @determined_build_group_status_and_which = T.let(nil, T.nilable([T::Boolean, T.nilable(String)]))
    nil
  end

  def cond; end;

  sig {returns([T::Boolean, T.nilable(String)])}
  private def determined_build_group_status_and_which
    @determined_build_group_status_and_which ||= [true, "fail"]
  end
end
