# typed: strict
# frozen_string_literal: true

module Prism
  class Node
    extend T::Sig

    sig { returns(T.nilable(RBI::Type)) }
    def spoom_type
      instance_variable_get(:@spoom_type)
    end

    sig { params(spoom_type: T.nilable(RBI::Type)).void }
    def spoom_type=(spoom_type)
      instance_variable_set(:@spoom_type, spoom_type)
    end
  end

  class ClassNode
    extend T::Sig

    sig { returns(T.nilable(Spoom::Model::SymbolDef)) }
    def spoom_symbol_def
      instance_variable_get(:@spoom_symbol_def)
    end

    sig { params(symbol_def: T.nilable(Spoom::Model::SymbolDef)).void }
    def spoom_symbol_def=(symbol_def)
      instance_variable_set(:@spoom_symbol_def, symbol_def)
    end

    sig { returns(T.nilable(Spoom::Model::Symbol)) }
    def spoom_superclass_symbol
      superclass = self.superclass

      case superclass
      when Prism::ConstantReadNode
        superclass.spoom_symbol
      when Prism::ConstantPathNode
        superclass.spoom_symbol
      end
    end
  end

  class ModuleNode
    extend T::Sig

    sig { returns(T.nilable(Spoom::Model::SymbolDef)) }
    def spoom_symbol_def
      instance_variable_get(:@spoom_symbol_def)
    end

    sig { params(symbol_def: T.nilable(Spoom::Model::SymbolDef)).void }
    def spoom_symbol_def=(symbol_def)
      instance_variable_set(:@spoom_symbol_def, symbol_def)
    end
  end

  class CallNode
    extend T::Sig

    sig { returns(T.nilable(T.any(Spoom::Model::Attr, Spoom::Model::Method))) }
    def spoom_method_symbol
      instance_variable_get(:@spoom_method_symbol)
    end

    sig { params(method_symbol: T.nilable(T.any(Spoom::Model::Attr, Spoom::Model::Method))).void }
    def spoom_method_symbol=(method_symbol)
      instance_variable_set(:@spoom_method_symbol, method_symbol)
    end
  end

  class ConstantReadNode
    extend T::Sig

    sig { returns(T.nilable(Spoom::Model::Symbol)) }
    def spoom_symbol
      instance_variable_get(:@spoom_symbol)
    end

    sig { params(symbol: T.nilable(Spoom::Model::Symbol)).void }
    def spoom_symbol=(symbol)
      instance_variable_set(:@spoom_symbol, symbol)
    end
  end

  class ConstantPathNode
    extend T::Sig

    sig { returns(T.nilable(Spoom::Model::Symbol)) }
    def spoom_symbol
      instance_variable_get(:@spoom_symbol)
    end

    sig { params(symbol: T.nilable(Spoom::Model::Symbol)).void }
    def spoom_symbol=(symbol)
      instance_variable_set(:@spoom_symbol, symbol)
    end
  end

  class ConstantWriteNode
    extend T::Sig

    sig { returns(T.nilable(Spoom::Model::SymbolDef)) }
    def spoom_symbol_def
      instance_variable_get(:@spoom_symbol_def)
    end

    sig { params(symbol_def: T.nilable(Spoom::Model::SymbolDef)).void }
    def spoom_symbol_def=(symbol_def)
      instance_variable_set(:@spoom_symbol_def, symbol_def)
    end
  end

  class ConstantPathWriteNode
    extend T::Sig

    sig { returns(T.nilable(Spoom::Model::SymbolDef)) }
    def spoom_symbol_def
      instance_variable_get(:@spoom_symbol_def)
    end

    sig { params(symbol_def: T.nilable(Spoom::Model::SymbolDef)).void }
    def spoom_symbol_def=(symbol_def)
      instance_variable_set(:@spoom_symbol_def, symbol_def)
    end
  end

  class DefNode
    extend T::Sig

    sig { returns(T.nilable(Spoom::Model::SymbolDef)) }
    def spoom_symbol_def
      instance_variable_get(:@spoom_symbol_def)
    end

    sig { params(symbol_def: T.nilable(Spoom::Model::SymbolDef)).void }
    def spoom_symbol_def=(symbol_def)
      instance_variable_set(:@spoom_symbol_def, symbol_def)
    end
  end
end
