# typed: true
# frozen_string_literal: true

class Side
  def foo(cond)
    a = 1
    a.foo(a, a = cond ? true : 2); # error: Method `foo` does not exist
  end
end
