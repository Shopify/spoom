# typed: strict

module Kernel
  sig { params(args: T.untyped).returns(String) }
  def to_json(*args); end
end
