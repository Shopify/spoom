# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    extend T::Sig

    class Error < Spoom::Error; end

    # A Symbol is a uniquely named entity in the Ruby codebase
    #
    # A symbol can have multiple definitions, e.g. a class can be reopened.
    # Sometimes a symbol can have multiple definitions of different types,
    # e.g. `foo` method can be defined both as a method and as an attribute accessor.
    class Symbol
      extend T::Sig

      # The full, unique name of this symbol
      sig { returns(String) }
      attr_reader :full_name

      # The definitions of this symbol (where it exists in the code)
      sig { returns(T::Array[SymbolDef]) }
      attr_reader :definitions

      sig { params(full_name: String).void }
      def initialize(full_name)
        @full_name = full_name
        @definitions = T.let([], T::Array[SymbolDef])
      end

      # The short name of this symbol
      sig { returns(String) }
      def name
        T.must(@full_name.split("::").last)
      end

      sig { returns(String) }
      def to_s
        @full_name
      end
    end

    # A SymbolDef is a definition of a Symbol
    #
    # It can be a class, module, constant, method, etc.
    # A SymbolDef has a location pointing to the actual code that defines the symbol.
    class SymbolDef
      extend T::Sig
      extend T::Helpers

      abstract!

      # The symbol this definition belongs to
      sig { returns(Symbol) }
      attr_reader :symbol

      # The enclosing namespace this definition belongs to
      sig { returns(T.nilable(Namespace)) }
      attr_reader :owner

      # The actual code location of this definition
      sig { returns(Location) }
      attr_reader :location

      sig { params(symbol: Symbol, owner: T.nilable(Namespace), location: Location).void }
      def initialize(symbol, owner:, location:)
        @symbol = symbol
        @owner = owner
        @location = location

        symbol.definitions << self
        owner.children << self if owner
      end

      # The full name of the symbol this definition belongs to
      sig { returns(String) }
      def full_name
        @symbol.full_name
      end

      # The short name of the symbol this definition belongs to
      sig { returns(String) }
      def name
        @symbol.name
      end
    end

    # A class or module
    class Namespace < SymbolDef
      abstract!

      sig { returns(T::Array[SymbolDef]) }
      attr_reader :children

      sig { returns(T::Array[Mixin]) }
      attr_reader :mixins

      sig { params(symbol: Symbol, owner: T.nilable(Namespace), location: Location).void }
      def initialize(symbol, owner:, location:)
        super(symbol, owner: owner, location: location)

        @children = T.let([], T::Array[SymbolDef])
        @mixins = T.let([], T::Array[Mixin])
      end
    end

    class SingletonClass < Namespace; end

    class Class < Namespace
      sig { returns(T.nilable(String)) }
      attr_accessor :superclass_name

      sig do
        params(
          symbol: Symbol,
          owner: T.nilable(Namespace),
          location: Location,
          superclass_name: T.nilable(String),
        ).void
      end
      def initialize(symbol, owner:, location:, superclass_name: nil)
        super(symbol, owner: owner, location: location)

        @superclass_name = superclass_name
      end
    end

    class Module < Namespace; end

    class Constant < SymbolDef
      sig { returns(String) }
      attr_reader :value

      sig { params(symbol: Symbol, owner: T.nilable(Namespace), location: Location, value: String).void }
      def initialize(symbol, owner:, location:, value:)
        super(symbol, owner: owner, location: location)

        @value = value
      end
    end

    # A method or an attribute accessor
    class Property < SymbolDef
      abstract!

      sig { returns(T::Array[Sig]) }
      attr_reader :sigs

      sig { params(symbol: Symbol, owner: T.nilable(Namespace), location: Location, sigs: T::Array[Sig]).void }
      def initialize(symbol, owner:, location:, sigs: [])
        super(symbol, owner: owner, location: location)

        @sigs = sigs
      end
    end

    class Method < Property; end

    class Attr < Property
      abstract!
    end

    class AttrReader < Attr; end
    class AttrWriter < Attr; end
    class AttrAccessor < Attr; end

    # A mixin (include, prepend, extend) to a namespace
    class Mixin
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String).void }
      def initialize(name)
        @name = name
      end
    end

    class Include < Mixin; end
    class Prepend < Mixin; end
    class Extend < Mixin; end

    # A Sorbet signature (sig block)
    class Sig
      extend T::Sig

      sig { returns(String) }
      attr_reader :string

      sig { params(string: String).void }
      def initialize(string)
        @string = string
      end
    end

    # Model

    # All the symbols registered in this model
    sig { returns(T::Hash[String, Symbol]) }
    attr_reader :symbols

    sig { void }
    def initialize
      @symbols = T.let({}, T::Hash[String, Symbol])
    end

    # Get a symbol by it's full name
    #
    # Raises an error if the symbol is not found
    sig { params(full_name: String).returns(Symbol) }
    def [](full_name)
      symbol = @symbols[full_name]
      raise Error, "Symbol not found: #{full_name}" unless symbol

      symbol
    end

    # Register a new symbol by it's full name
    #
    # If the symbol already exists, it will be returned.
    sig { params(full_name: String).returns(Symbol) }
    def register_symbol(full_name)
      @symbols[full_name] ||= Symbol.new(full_name)
    end
  end
end
