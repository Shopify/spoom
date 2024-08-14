# typed: ignore
# frozen_string_literal: true

class Base
  sig { returns(Integer) }
  def base; end
end

class Foo < Base
  sig { void }
  def foo
    base
  end
end

foo = Foo.new
foo.foo
