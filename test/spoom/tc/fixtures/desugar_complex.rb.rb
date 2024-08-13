# typed: strict

class MyBasicClass < BasicObject
  extend T::Sig

  sig {params(x: Complex).void}
  def foo(x)
    Kernel.puts x
  end

  sig {returns(Complex)}
  def bar
    11i
  end

  sig {void}
  def baz
    Kernel.puts 2i
  end
end

class MyKernelClass
  extend T::Sig

  sig {params(x: Complex).void}
  def foo(x)
    puts x
  end
end

bc = MyBasicClass.new
bc.foo(1i)
bc.foo(-1i)
bc.foo(Complex(0, 1))
bc.foo(-Complex(0, 1))
bc.foo(Complex(0, -1))
 bc.foo(-1)
#       ^^ error: Expected `Complex` but found `Integer(-1)` for argument `x`

MyBasicClass.new.bar

kc = MyKernelClass.new
kc.foo(1i)
kc.foo(-1i)
kc.foo(Complex(0, 1))
kc.foo(-Complex(0, 1))
kc.foo(Complex(0, -1))
 kc.foo(-1)
#       ^^ error: Expected `Complex` but found `Integer(-1)` for argument `x`
