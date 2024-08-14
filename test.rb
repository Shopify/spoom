# typed: ignore
# frozen_string_literal: true

module Foo
  sig { returns(T::Array[String]) }
  def self.foo
  end
end

Foo.foo.each do |x|
end
