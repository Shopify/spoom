# typed: true
# frozen_string_literal: true

module Spoom
  class Counter
    extend T::Sig

    sig { returns(T::Hash[String, Integer]) }
    attr_reader :values

    def initialize
      @values = T.let(Hash.new(0), T::Hash[String, Integer])
    end

    sig { params(name: String).void }
    def inc(name)
      @values[name] = T.must(@values[name]) + 1
    end

    sig { params(name: String).returns(Integer) }
    def value(name)
      T.must(@values[name])
    end

    def print
      puts "Values:"
      @values.each do |name, value|
        puts "  #{name}: #{value}"
      end
    end
  end
end
