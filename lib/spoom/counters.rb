# typed: strict
# frozen_string_literal: true

module Spoom
  #: [K = String, V = Integer, Elem = [String, Integer]]
  class Counters < Hash
    #: -> void
    def initialize
      super(0)
    end

    #: (String) -> void
    def increment(key)
      self[key] += 1
    end

    #: (String) -> Integer
    def [](key)
      super(key) #: as Integer
    end
  end
end
