# typed: true
extend T::Sig

sig {params(x: Integer, y: Integer, z: Integer).returns(Integer)}
def f(x, y, z)
  x + y + z
end

args = [1, 2, 3]
T.assert_type!(f(*args), Integer)

T.assert_type!(f(1, *[2, 3]), Integer)

T.reveal_type(f(*T.unsafe(nil))) # error: type: `T.untyped`

args = [*(1..3), 5, 6]

sig {params(x: Integer, blk: T.proc.params(x: Integer).returns(Integer)).returns(Integer)}
def yields(x, &blk)
  blk.call(x)
end

yields(*[1]) do |x|
  T.assert_type!(x, Integer)
  x
end

proc = ->(x){x}
yields(*[1], &T.unsafe(proc))
