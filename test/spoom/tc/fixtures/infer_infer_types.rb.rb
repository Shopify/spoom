# typed: true

# This file tests the implementation of type syntax used by
# `infer`. In the future we hope to migrate to this being the sole C++
# implementation, but for now inference and the resolver both
# effectively contain type syntax implementations.


T.reveal_type(T::Array[T.any(Symbol, String)].new) # error: type: `T::Array[T.any(Symbol, String)]`

module A; end
module B; end

T.reveal_type(T::Array[T.all(A, B)].new) # error: type: `T::Array[T.all(A, B)]`

T.reveal_type(T::Array[T.untyped].new) # error: type: `T::Array[T.untyped]`

T.assert_type!(
  T::Array[[T::Array[Integer], T::Array[Integer]]].new,
  T::Array[[T::Array[Integer], T::Array[Integer]]])

class C; end

extend T::Sig
sig {returns(T::Array[T.class_of(C)])}
def f
  [C]
end
