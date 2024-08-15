class A
  def a; end
end

class B
  def b; end
end

sig { params(a_or_b: T.any(A, B)).void }
def foo(a_or_b)
  case a_or_b
  when A
    a_or_b.a
  when B
    a_or_b.b
  end
end
