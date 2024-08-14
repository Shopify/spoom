# typed: strict
# frozen_string_literal: true

module RBI
  class Type
    extend T::Sig

    sig { returns(T.nilable(Spoom::Model::Symbol)) }
    def spoom_symbol
      instance_variable_get(:@spoom_symbol)
    end

    sig { params(spoom_symbol: T.nilable(Spoom::Model::Symbol)).void }
    def spoom_symbol=(spoom_symbol)
      instance_variable_set(:@spoom_symbol, spoom_symbol)
    end
  end
end
