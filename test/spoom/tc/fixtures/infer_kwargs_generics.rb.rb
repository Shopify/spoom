# typed: true
class S
  extend T::Sig
  sig {params(value: T.untyped, path: T.untyped).returns(NilClass)}
  def self.has_kwarg(value, path: [])
  end
end
class C
  extend T::Generic
  extend T::Sig
  A = type_member
  sig {params(value:A).void}
  def dd(value)
    S.has_kwarg(value)
  end
end
