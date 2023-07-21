require "sorbet-runtime"

class Foo
  include T::Props

  prop :x, String
end

foo = Foo.new
foo.x = "hello"
puts foo.x # => "hello"
