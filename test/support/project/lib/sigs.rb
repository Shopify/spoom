# typed: true
# frozen_string_literal: true

class SigsTest
  extend T::Sig

  sig { params(a: Integer).returns(String) }
  def bar(a)
    a.to_s
  end
end

y = SigsTest.new
y.bar(42)
