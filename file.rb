# typed: ugnore
# frozen_string_literal: true

class Foo
  def foo; end # sig: Missing sig

  foo
# ^^^ type: Method `foo` does not exist

  def bar(x, y); end
  # ^ error: Missing sig

  class Foo
    def foo; end
    #   ^^^ error: Method `foo` does not exist
  end
end

class Foo
    x = 1
  # ^ type
end
