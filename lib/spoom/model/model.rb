# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    extend T::Sig

    class Error < Spoom::Error; end

    # A Symbol is a uniquely named entity in the Ruby codebase
    class Symbol
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(String) }
      attr_reader :full_name

      sig { returns(T::Array[Location]) }
      attr_reader :locs

      # sig { returns(T::Array[SymbolDef]) }
      # attr_reader :definitions

      sig { params(full_name: String, locs: T::Array[Location]).void }
      def initialize(full_name, locs: [])
        @full_name = full_name
        @locs = locs
        # @definitions = T.let([], T::Array[SymbolDef])
      end

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

    class Namespace < Symbol
      sig { returns(T::Array[Mixin]) }
      attr_reader :mixins

      sig { params(full_name: String, locs: T::Array[Location]).void }
      def initialize(full_name, locs: [])
        super(full_name, locs: locs)

        @mixins = T.let([], T::Array[Mixin])
      end
    end

    class Class < Namespace
      sig { returns(T.nilable(String)) }
      attr_accessor :superclass_name

      sig { params(full_name: String, superclass_name: T.nilable(String), locs: T::Array[Location]).void }
      def initialize(full_name, superclass_name: nil, locs: [])
        super(full_name, locs: locs)

        @superclass_name = superclass_name
      end
    end

    class Module < Namespace; end
    # class Constant < Symbol; end
    # class Method < Symbol; end
    # class Accessor < Symbol; end

    class Mixin
      extend T::Sig

      class Kind < T::Enum
        enums do
          Include = new("include")
          Prepend = new("prepend")
          Extend = new("extend")
        end
      end

      sig { returns(Kind) }
      attr_reader :kind

      sig { returns(String) }
      attr_reader :name

      sig { params(kind: Kind, name: String).void }
      def initialize(kind, name)
        @kind = kind
        @name = name
      end
    end

    # A SymbolDef is a definition of a Symbol
    #
    # It can be a class, module, constant, method, etc.
    # Note that a class can be reopened therefore a symbol can have more than one definition.
    # class SymbolDef
    #   extend T::Sig
    #   extend T::Helpers

    #   abstract!

    #   sig { returns(Symbol) }
    #   attr_reader :symbol

    #   sig { returns(Location) }
    #   attr_reader :location

    #   sig { params(symbol: Symbol, location: Location).void }
    #   def initialize(symbol, location)
    #     @location = location

    #     @symbol = symbol
    #     symbol.definitions << self
    #   end
    # end

    # The Symbol for of a Class or a Module
    # class Scope < Symbol
    #   extend T::Sig
    #   extend T::Helpers

    #   abstract!

    #   sig { abstract.returns(T::Array[ScopeDef]) }
    #   def definitions; end

    #   sig { returns(String) }
    #   def name
    #     T.must(@full_name.split("::").last)
    #   end
    # end

    # class NamespaceDef < SymbolDef
    #   extend T::Sig
    #   extend T::Helpers

    #   abstract!

    #   sig { abstract.returns(Symbol) }
    #   def symbol; end
    # end

    # class Class < Scope
    #   sig { override.returns(T::Array[ClassDef]) }
    #   attr_reader :definitions

    #   sig { override.params(full_name: String).void }
    #   def initialize(full_name)
    #     super(full_name)

    #     @definitions = T.let([], T::Array[ClassDef])
    #   end
    # end

    # class ClassDef < NamespaceDef
    # end

    # class Module < Scope
    #   sig { override.returns(T::Array[ModuleDef]) }
    #   attr_reader :definitions

    #   sig { override.params(full_name: String).void }
    #   def initialize(full_name)
    #     super(full_name)

    #     @definitions = T.let([], T::Array[ModuleDef])
    #   end
    # end

    # class ModuleDef < NamespaceDef
    # end

    # class Constant < Symbol
    #   sig { override.returns(T::Array[ConstantDef]) }
    #   attr_reader :definitions

    #   sig { override.params(full_name: String).void }
    #   def initialize(full_name)
    #     super(full_name)

    #     @definitions = T.let([], T::Array[ConstantDef])
    #   end
    # end

    # class ConstantDef < SymbolDef
    # end

    # class Method < Symbol
    #   sig { override.returns(T::Array[MethodDef]) }
    #   attr_reader :definitions

    #   sig { override.params(full_name: String).void }
    #   def initialize(full_name)
    #     super(full_name)

    #     @definitions = T.let([], T::Array[MethodDef])
    #   end
    # end

    # class MethodDef < SymbolDef
    # end

    # class AccessorDef < SymbolDef
    # end

    # Model

    sig { returns(T::Hash[String, Symbol]) }
    attr_reader :symbols

    sig { returns(Poset[Symbol]) }
    attr_reader :poset

    # sig { returns(T::Hash[String, SymbolDef]) }
    # attr_reader :location_to_symbol_def

    sig { void }
    def initialize
      @symbols = T.let({}, T::Hash[String, Symbol])
      @poset = T.let(Poset[Symbol].new, Poset[Symbol])
      # @location_to_symbol_def = T.let({}, T::Hash[String, SymbolDef])
    end

    # sig { params(full_name: String, location: Location).returns(ClassDef) }
    # def register_class_def(full_name, location)
    #   symbol = @symbols[full_name] ||= Class.new(full_name)
    #   symbol_def = ClassDef.new(symbol, location)
    #   @location_to_symbol_def[location.to_s] = symbol_def
    #   symbol_def
    # end

    # sig { params(full_name: String, location: Location).returns(ModuleDef) }
    # def register_module_def(full_name, location)
    #   symbol = @symbols[full_name] ||= Module.new(full_name)
    #   symbol_def = ModuleDef.new(symbol, location)
    #   @location_to_symbol_def[location.to_s] = symbol_def
    #   symbol_def
    # end

    # sig { params(full_name: String, location: Location).returns(MethodDef) }
    # def register_method_def(full_name, location)
    #   symbol = @symbols[full_name] ||= Method.new(full_name)
    #   symbol_def = MethodDef.new(symbol, location)
    #   @location_to_symbol_def[location.to_s] = symbol_def
    #   symbol_def
    # end

    # sig { params(full_name: String, location: Location).returns(ConstantDef) }
    # def register_constant_def(full_name, location)
    #   symbol = @symbols[full_name] ||= Constant.new(full_name)
    #   symbol_def = ConstantDef.new(symbol, location)
    #   @location_to_symbol_def[location.to_s] = symbol_def
    #   symbol_def
    # end

    # sig { params(full_name: String, location: Location).returns(AccessorDef) }
    # def register_accessor_def(full_name, location)
    #   symbol = @symbols[full_name] ||= Accessor.new(full_name)
    #   symbol_def = AccessorDef.new(symbol, location)
    #   @location_to_symbol_def[location.to_s] = symbol_def
    #   symbol_def
    # end
    #

    sig { void }
    def finalize
      compute_symbol_hierarchy
    end

    private

    sig { void }
    def compute_symbol_hierarchy
      @symbols.dup.each do |_full_name, symbol|
        next unless symbol.is_a?(Namespace)

        @poset.add_node(symbol)

        if symbol.is_a?(Class)
          superclass_name = symbol.superclass_name
          if superclass_name
            superclass = resolve_symbol(superclass_name, context: symbol)
            @poset.add_direct_edge(symbol, superclass)
          end
        end

        symbol.mixins.each do |mixin|
          next if mixin.kind == Mixin::Kind::Extend

          target = resolve_symbol(mixin.name, context: symbol)
          @poset.add_direct_edge(symbol, target)
        end
      end
    end

    sig { params(full_name: String, context: Symbol).returns(Symbol) }
    def resolve_symbol(full_name, context:)
      if full_name.start_with?("::")
        full_name.delete_prefix!("::")
        return @symbols[full_name] ||= UnresolvedSymbol.new(full_name)
      end

      target = T.let(@symbols[full_name], T.nilable(Symbol))
      return target if target

      parts = context.full_name.split("::")
      until parts.empty?
        target_name = "#{parts.join("::")}::#{full_name}"
        target = @symbols[target_name]
        return target if target

        parts.pop
      end

      @symbols[full_name] = UnresolvedSymbol.new(full_name)
    end
  end
end

# TODO: Keep only classes/modules
# TODO: Resolve inheritance / module hierarchy
# TODO: Freeze -> linearize ancestors?
# TODO: Use in dead code plugins
