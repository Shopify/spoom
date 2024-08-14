# typed: true
# frozen_string_literal: true

module Foo
  extend T::Sig

  class Bar; end
  def foo; end # error: Missing sig

  foo
  # ^^^ error: Method `foo` does not exist

  FOO = 42
  ::FOO = 42

  sig { params(x: String, y: Integer).void }
  def bar(x, y)
    foo(x)
    puts FOO.round(y)
  end
  # ^ error: Missing sig

  class Baz < Bar
    def foo; end
    # ^^^ error: Method `foo` does not exist

    def bar(z)
      if z.is_a?(Integer)
        puts x.round(2)
      end
    end
    # ^ error: Method `bar` does not exist
  end

  ::Baz.new.foo

  puts FOO
end
