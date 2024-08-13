# typed: true
class Parent
  extend T::Sig

  sig {returns(T.self_type)}
  def returns_self
    self
  end
end
class Normal < Parent
end

class Generic < Parent
  extend T::Generic
  TM = type_member()

  sig {returns(Generic[T.self_type])} # error: Only top-level T.self_type is supported
  def bad
   Generic[T.untyped].new
  end
end

T.assert_type!(Normal.new.returns_self, Normal)
T.assert_type!(Generic[String].new.returns_self, Generic[String])

module B
end

a = Generic[String].new
if a.is_a?(B)
  T.assert_type!(a.returns_self, T.all(Generic[String], B))
end

class Array
    extend T::Sig

    sig {returns(T.self_type)}
    def returns_self
      self
    end
end

T.assert_type!([1, 2].returns_self, [Integer, Integer])

class A
end

module B
  extend T::Sig

  sig {returns(T.self_type)}
  def returns_self
     self
  end
end

s = A.new

def rnd
end

while (rnd)
  if s.is_a?(B)
    s = s.returns_self
  end
end

puts s
