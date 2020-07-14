# typed: true
# frozen_string_literal: true

class HoverTest
  extend T::Sig

  sig { params(a: Integer).returns(String) }
  def foo(a)
    a.to_s
  end
end

ht = HoverTest.new
ht.foo(42)
