# typed: true

class TestSelf
  extend T::Sig

  sig do
    params(s: self)
    .returns(self)
  end
  def good1(s)
    self
  end

  sig do
    returns(self)
  end
  def pass()
    good1(self)
  end
end


class TestSelfGeneric
  extend T::Generic
  extend T::Sig

  Elem = type_member
  sig do
    params(s: self)
    .returns(self)
  end
  def good1(s)
    self
  end

  sig do
    returns(self)
  end
  def pass()
    good1(self)
  end
end
