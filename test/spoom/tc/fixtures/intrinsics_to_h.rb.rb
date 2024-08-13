# typed: true

T.assert_type!(
  [].to_h,
  T::Hash[T.untyped, T.untyped]
)

T.assert_type!(
  [[:a, 1], [:b, 2]].to_h,
  T::Hash[Symbol, Integer]
)

["hi"].to_h # error: Expected `T::Enumerable[[T.type_parameter(:U), T.type_parameter(:V)]]`

T.assert_type!(
  T.cast([], T::Enumerable[[String, Symbol]]).to_h,
  T::Hash[String, Symbol],
)
