# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    extend T::Sig

    # Defs

    class SymbolDef
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(Location) }
      attr_reader :location

      sig { params(location: Location).void }
      def initialize(location)
        @location = location
      end
    end

    class ScopeDef < SymbolDef
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(T::Array[Ref]) }
      attr_reader :constant_refs

      sig { override.params(location: Location).void }
      def initialize(location)
        super(location)

        @constant_refs = T.let([], T::Array[Ref])
      end
    end

    class ClassDef < ScopeDef
    end

    class ModuleDef < ScopeDef
    end

    class ConstantDef < SymbolDef
    end

    # Global

    class Symbol
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(String) }
      attr_reader :full_name

      sig { params(full_name: String).void }
      def initialize(full_name)
        @full_name = full_name
      end

      sig { abstract.returns(T::Array[SymbolDef]) }
      def defs; end
    end

    class Scope < Symbol
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { abstract.returns(T::Array[ScopeDef]) }
      def defs; end
    end

    class Class < Scope
      sig { override.returns(T::Array[ClassDef]) }
      attr_reader :defs

      sig { override.params(full_name: String).void }
      def initialize(full_name)
        super(full_name)

        @defs = T.let([], T::Array[ClassDef])
      end
    end

    class Module < Scope
      sig { override.returns(T::Array[ModuleDef]) }
      attr_reader :defs

      sig { override.params(full_name: String).void }
      def initialize(full_name)
        super(full_name)

        @defs = T.let([], T::Array[ModuleDef])
      end
    end

    class Constant < Symbol
      sig { override.returns(T::Array[ConstantDef]) }
      attr_reader :defs

      sig { override.params(full_name: String).void }
      def initialize(full_name)
        super(full_name)

        @defs = T.let([], T::Array[ConstantDef])
      end
    end

    # Refs

    class Ref
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(Location) }
      attr_reader :location

      sig { returns(T.nilable(Symbol)) }
      attr_accessor :target

      sig { params(name: String, location: Location).void }
      def initialize(name, location)
        @name = name
        @location = location
        @target = T.let(nil, T.nilable(Symbol))
      end

      sig { returns(T::Boolean) }
      def resolved?
        !!@target
      end

      sig { returns(String) }
      def to_s
        if @target
          @target.full_name
        else
          "<<#{@name}>>"
        end
      end
    end

    # Model

    sig { returns(T::Hash[String, Symbol])}
    attr_reader :symbols

    sig { void }
    def initialize
      @symbols = T.let({}, T::Hash[String, Symbol])
    end

    sig { params(full_name: String, scope_def: ClassDef).void }
    def register_class_def(full_name, scope_def)
      scope = @symbols[full_name] ||= Class.new(full_name)
      #raise "#{full_name} previously defined as a #{scope.class}" unless scope.is_a?(Class)
      scope.defs << scope_def
    end

    sig { params(full_name: String, scope_def: ModuleDef).void }
    def register_module_def(full_name, scope_def)
      scope = @symbols[full_name] ||= Module.new(full_name)
      # raise "#{full_name} previously defined as a #{scope.class}" unless scope.is_a?(Module)
      scope.defs << scope_def
    end

    sig { params(full_name: String, const_def: ConstantDef).void }
    def register_constant_def(full_name, const_def)
      scope = @symbols[full_name] ||= Constant.new(full_name)
      # raise "#{full_name} previously defined as a #{scope.class}" unless scope.is_a?(Constant)
      scope.defs << const_def
    end

    sig { void }
    def finalize
      @symbols.each_value do |symbol|
        next unless symbol.is_a?(Scope)

        resolve_constant_refs(symbol)
      end
    end

    private

    sig { params(scope: Scope).void }
    def resolve_constant_refs(scope)
      scope.defs.each do |scope_def|
        scope_def.constant_refs.each do |ref|
          ref.target = resolve_name(ref.name, scope)
        end
      end
    end

    sig { params(name: String, context: Scope).returns(T.nilable(Symbol)) }
    def resolve_name(name, context)
      # 1. Look by fully qualified name directly
      if name.start_with?("::")
        target = T.let(@symbols[name], T.nilable(Symbol))
        return target if target
      end

      # 2. Look inside the parent namespaces
      namespaces = context.full_name.split("::")
      until namespaces.empty?
        full_name = namespaces.join("::") + "::" + name
        target = @symbols[full_name]
        return target if target

        namespaces.pop
      end

      # 3. Look inside the global namespace
      @symbols[name]
    end
  end
end
