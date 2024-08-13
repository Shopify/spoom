# typed: strict
class Parent
  def initialize # error: does not have a `sig`
    @ivar = T.let(0, Integer)
    @ivar2 = T.let(0, Integer)
  end

  @@class_var = T.let("", String)

  @@class_var = "hi"

  def hi # error: does not have a `sig`
    @ivar = 1
    @ivar2
  end
end

module Mixin
  @@mixin_cvar = T.let(0, Integer)
  @@mixin_cvar
end

class Child < Parent
  include Mixin

  @@class_var
  @@mixin_cvar
  @@undefined_cvar # error: Use of undeclared variable

  def child_method # error: does not have a `sig`
    @@class_var
    @@mixin_cvar
    @ivar2
    @undefinedivar # error: Use of undeclared variable
  end
end

Alias = Parent
class Child1 < Alias
  @@class_var
end
