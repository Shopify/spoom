# typed: true

class HasAbstract
  extend T::Sig
  extend T::Helpers
  abstract!

  sig {params(x: Integer).abstract.returns(String)}
  def abstract(x)
  end

  sig {abstract.void}
  def self.abstract_singleton
  end

  sig {params(x: Integer).abstract.returns(String)}
  def abstract_with_body(x)
    14 # error: Abstract methods must not contain any code in their body
  end

  sig {abstract.params(x: T.untyped).void}
  def abstract_with_splat(*x)
  end

  sig {abstract.params(blk: T.proc.void).void}
  def abstract_with_block(&blk)
  end
end

class InterfaceClass
  extend T::Sig
  extend T::Helpers

  interface! # error: Classes can't be interfaces
end

class AbstractMethodNotClass
  extend T::Sig
  extend T::Helpers

  sig {returns(T.untyped).abstract}
  def f; end # error: you must mark your class/module as abstract
end

module InterfaceModule
  extend T::Sig
  extend T::Helpers

  interface!

  sig {returns(T.untyped)}
  def f # error: must be declared abstract
    0
  end
end
