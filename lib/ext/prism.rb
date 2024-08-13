# typed: strict
# frozen_string_literal: true

module Prism
  class Node
    extend T::Sig

    sig { returns(Symbol) }
    def spoom_symbol
      instance_variable_get(:@spoom_symbol)
    end

    
    def spoom_symbol=(symbol)
      instance_variable_set(:@spoom_symbol, symbol)
    end
  end
end
