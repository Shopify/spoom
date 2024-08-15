class A
  def a; end
end

class B
  def b; end
end

sig { params(a_or_b: T.any(A, B)).void }
def foo1(a_or_b)
  return a_or_b.a if a_or_b.is_a?(A)

  a_or_b.b
end

sig { params(a_or_b: T.any(A, B)).void }
def foo2(a_or_b)
  if a_or_b.is_a?(A)
    a_or_b.a
  else
    a_or_b.b
  end
end

sig { params(a_or_b: T.any(A, B)).void }
def foo3(a_or_b)
  a_or_b.is_a?(A) && a_or_b.a
  a_or_b.a
#        ^ error: Method `a` does not exist on `B`
end
