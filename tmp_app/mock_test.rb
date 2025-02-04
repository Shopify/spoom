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

  sig { returns(T.self_type) }
  def any_instance
    # ...
    self
  end
end

class Object
  extend Mocha
end

class Mocha::Mock
end

class IdentityClient
  extend T::Sig

  sig { params(session: Session).returns(IdentityResult) }
  def self.check_identity_session_singleton(session)
    IdentityResult.new(success: true)
  end

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

  setup do
    @receiver_node = T.let(nil, T.nilable(T.untyped))
  end

  sig { returns(T::Boolean) }
  def expected
    true
  end

  def untyped
    nil
  end

  sig { returns(Mocha::Mock) }
  def mock
    Mocha::Mock.new
  end

  test "SessionController redirects to homepage if identity session is valid" do
    # # # bad
    # IdentityClient.expects(:foo).returns(true)
    # IdentityClient.expects(:check_identity_session_singleton).returns(expected)
    # IdentityClient.expects(:check_identity_session_singleton).with(1, 2, 3).returns(true)
    # IdentityClient.expects(:check_identity_session_singleton).with("").returns(true)
    # IdentityClient.expects(:check_identity_session).with("").returns(true)
    # IdentityClient.any_instance.expects(:check_identity_session_singleton).returns(expected)
    # IdentityClient.any_instance.expects(:foo).returns(true)
    # IdentityClient.any_instance.expects(:check_identity_session).returns(expected)
    # IdentityClient.any_instance.expects(:check_identity_session).with(1, 2, 3).returns(true)
    # IdentityClient.any_instance.expects(:check_identity_session).with("").returns(true)

    # # # good
    IdentityClient.expects(:check_identity_session_singleton).with(Session.new).returns(IdentityResult.new(success: true))
    IdentityClient.expects(:check_identity_session_singleton).returns(IdentityResult.new(success: true))
    IdentityClient.expects(:check_identity_session).returns(@var)
    IdentityClient.any_instance.expects(:check_identity_session).with(Session.new).returns(IdentityResult.new(success: true))
    IdentityClient.any_instance.expects(:check_identity_session).returns(untyped)
    IdentityClient.any_instance.expects(:check_identity_session).returns(mock)
    IdentityClient.any_instance.expects(:check_identity_session).returns(@var)

    # ignored
    @receiver_node.expects(:foo).returns(true)
  end
end
