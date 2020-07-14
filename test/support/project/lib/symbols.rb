# typed: true
# frozen_string_literal: true

module Symbols
  class A
    attr_reader :a, :b

    def foo; end

    def bar; end

    def self.baz; end
  end

  class B < A
    include Symbols
    class C; end
  end
end

module OtherModule; end
class OtherClass; end
