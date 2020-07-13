# typed: true
# frozen_string_literal: true

class Foo
  sig { params(bar: Bar).returns(C) }
  def foo(bar)
  end
end

b = Foo.new(42)
b.foo(b, c)
