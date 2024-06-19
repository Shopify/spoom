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

    class UnresolvedSymbol < Symbol
      sig { override.returns(String) }
      def to_s
        "<#{@full_name}>"
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

      sig { returns(Visibility) }
      attr_reader :visibility

      sig { returns(T::Array[Sig]) }
      attr_reader :sigs

      sig do
        params(
          symbol: Symbol,
          owner: T.nilable(Namespace),
          location: Location,
          visibility: Visibility,
          sigs: T::Array[Sig],
        ).void
      end
      def initialize(symbol, owner:, location:, visibility:, sigs: [])
        super(symbol, owner: owner, location: location)

        @visibility = visibility
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

    class Visibility < T::Enum
      enums do
        Public = new("public")
        Protected = new("protected")
        Private = new("private")
      end
    end

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

    sig { returns(Poset[Symbol]) }
    attr_reader :symbols_hierarchy

    sig { void }
    def initialize
      @symbols = T.let({}, T::Hash[String, Symbol])
      @symbols_hierarchy = T.let(Poset[Symbol].new, Poset[Symbol])
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

    sig { params(full_name: String, context: Symbol).returns(Symbol) }
    def resolve_symbol(full_name, context:)
      if full_name.start_with?("::")
        full_name = full_name.delete_prefix("::")
        return @symbols[full_name] ||= UnresolvedSymbol.new(full_name)
      end

      target = T.let(@symbols[full_name], T.nilable(Symbol))
      return target if target

      parts = context.full_name.split("::")
      until parts.empty?
        target = @symbols["#{parts.join("::")}::#{full_name}"]
        return target if target

        parts.pop
      end

      @symbols[full_name] = UnresolvedSymbol.new(full_name)
    end

    sig { params(symbol: Symbol).returns(T::Array[Symbol]) }
    def supertypes(symbol)
      poe = @symbols_hierarchy[symbol]
      poe.ancestors
    end

    sig { params(symbol: Symbol).returns(T::Array[Symbol]) }
    def subtypes(symbol)
      poe = @symbols_hierarchy[symbol]
      poe.descendants
    end

    sig { void }
    def finalize!
      compute_symbols_hierarchy!
    end

    private

    sig { void }
    def compute_symbols_hierarchy!
      @symbols.dup.each do |_full_name, symbol|
        symbol.definitions.each do |definition|
          next unless definition.is_a?(Namespace)

          @symbols_hierarchy.add_element(symbol)

          if definition.is_a?(Class)
            superclass_name = definition.superclass_name
            if superclass_name
              superclass = resolve_symbol(superclass_name, context: symbol)
              @symbols_hierarchy.add_direct_edge(symbol, superclass)
            end
          end

          definition.mixins.each do |mixin|
            next if mixin.is_a?(Extend)

            target = resolve_symbol(mixin.name, context: symbol)
            @symbols_hierarchy.add_direct_edge(symbol, target)
          end
        end
      end
    end
  end
end
