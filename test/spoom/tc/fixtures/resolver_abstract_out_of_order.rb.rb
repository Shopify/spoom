# typed: true
class Impl # error: Missing definition for abstract method
  include Interface
end

module Interface
  extend T::Sig
  extend T::Helpers

  interface!

  sig {abstract.void}
  def f; end
end
