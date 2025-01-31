# typed: true
# frozen_string_literal: true

module Mocha
  extend T::Sig

  sig { params(method: Symbol).returns(T.self_type) }
  def expects(method)
    # ...
    self
  end

  sig { params(args: T.untyped).returns(T.self_type) }
  def with(*args)
    # ...
    self
  end

  sig { params(res: T.untyped).returns(T.self_type) }
  def returns(res)
    # ...
    self
  end
end

class Object
  extend Mocha
end

class IdentityClient
  extend T::Sig

  sig { params(session: Session).returns(IdentityResult) }
  def check_identity_session(session)
    IdentityResult.new(success: true)
  end
end

class IdentityResult
  extend T::Sig

  sig { params(success: T::Boolean).void }
  def initialize(success:)
  end
end

class Session; end

class MockTest # < ActionController::TestCase
  extend T::Sig

  sig { returns(T::Boolean) }
  def expected
    true
  end

  test "SessionController redirects to homepage if identity session is valid" do
    # bad
    IdentityClient.expects(:foo).returns(true)
    IdentityClient.expects(:check_identity_session).returns(expected)
    IdentityClient.expects(:check_identity_session).with(1, 2, 3).returns(true)
    IdentityClient.expects(:check_identity_session).with("").returns(true)

    # good
    IdentityClient.expects(:check_identity_session).with(Session.new).returns(IdentityResult.new(success: true))
  end

  # sig { params(receiver: IdentityClient).returns(T::Boolean) }
  # def __test_mock(receiver)
  #   __expected_res = T.let(T.unsafe(nil), T.type_of(expected))
  #   __expected_res = IdentityClient.check_identity_session("")
  #   receiver.check_identity_session(1, 2, 3)
  # end
end
