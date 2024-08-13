# typed: strict

extend T::Sig

class MyEnum < T::Enum
  enums do
  A = new
  B = new
  C = new
  D = new
  end
end

sig {params(x: T.any(MyEnum::A, MyEnum::B)).void}
def takes_a_or_b(x); end

sig {params(x: MyEnum::C).void}
def takes_c(x); end

sig {params(x: MyEnum).void}
def some_common_cases(x)
  case x
  when MyEnum::A, MyEnum::B
    takes_a_or_b(x)
  when MyEnum::C
    takes_c(x)
  else
    T.absurd(x) # error: Control flow could reach `T.absurd` because the type `MyEnum::D` wasn't handled
  end
end
