# typed: true

r = Random.new
T.assert_type!(r.rand, Float)
T.assert_type!(r.rand(1), Integer)
T.assert_type!(r.rand(1.0), Float)
T.assert_type!(r.rand(1..1), Integer)
T.assert_type!(r.rand(1.0..1.0), Float)
T.assert_type!(r.rand(36**8), Numeric)
T.assert_type!(r.rand((36**8..36**9)), Numeric)

T.assert_type!(Random.rand, Float)
T.assert_type!(Random.rand(1), Integer)
T.assert_type!(Random.rand(1.0), Float)
T.assert_type!(Random.rand(1..1), Integer)
T.assert_type!(Random.rand(1.0..1.0), Float)
T.assert_type!(Random.rand(36**8), Numeric)
T.assert_type!(Random.rand((36**8..36**9)), Numeric)
