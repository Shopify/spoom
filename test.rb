# typed: ignore
# frozen_string_literal: true

class Integer
  sig { params(x: Integer).returns(String) }
  def foo(x)
    x
    42
    y = 42
    # to_s
    y.to_s
  end

  sig { returns(String) }
  def to_s; end
end

# x = 0
# y = x
# z = y.to_s
# z1 = y.zzz
# z2 = y.foo
# z3 = 42 if true
