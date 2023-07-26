# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    extend T::Sig

    class Symbol
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

    class Ref
      extend T::Sig

      sig { returns(String) }
      attr_reader :full_name

      sig { params(full_name: String).void }
      def initialize(full_name)
        @full_name = full_name
      end

      sig { returns(String) }
      def to_s
        "<<#{full_name}>>"
      end
    end

    class Scope < Symbol
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(String) }
      attr_reader :full_name

      sig { returns(T::Array[T.any(Ref, Module)]) }
      attr_reader :includes

      sig { returns(T::Array[Attr]) }
      attr_reader :attrs

      sig { returns(T::Array[Method]) }
      attr_reader :defs

      sig { returns(T::Array[Prop]) }
      attr_reader :props

      sig { params(location: Location, full_name: String).void }
      def initialize(location, full_name)
        super(location)

        @full_name = full_name
        @defs = T.let([], T::Array[Method])
        @props = T.let([], T::Array[Prop])
        @includes = T.let([], T::Array[T.any(Ref, Module)])
        @attrs = T.let([], T::Array[Attr])
      end

      sig { params(full_name: String).returns(T::Boolean) }
      def descendant_of?(full_name)
        includes.any? { |i| i.full_name == full_name || (i.is_a?(Module) && i.descendant_of?(full_name)) }
      end
    end

    class Module < Scope
      extend T::Sig

      sig { returns(String) }
      def to_s
        "module #{full_name} (#{location})"
      end
    end

    class Class < Scope
      extend T::Sig

      sig { returns(T.nilable(T.any(Ref, Class))) }
      attr_accessor :superclass

      sig { params(location: Location, full_name: String, superclass: T.nilable(T.any(Ref, Class))).void }
      def initialize(location, full_name, superclass: nil)
        super(location, full_name)

        @superclass = superclass
      end

      sig { params(full_name: String).returns(T::Boolean) }
      def subclass_of?(full_name)
        superclass = self.superclass
        return false unless superclass

        superclass.full_name == full_name || (superclass.is_a?(Class) && superclass.subclass_of?(full_name))
      end

      sig { override.params(full_name: String).returns(T::Boolean) }
      def descendant_of?(full_name)
        superclass = self.superclass
        return true if superclass.is_a?(Class) && superclass.descendant_of?(full_name)

        super
      end

      sig { returns(String) }
      def to_s
        out = String.new
        out << "class #{full_name}"

        superclass = self.superclass
        case superclass
        when Class
          out << " < #{superclass.full_name}"
        when Ref
          out << " < <<#{superclass.full_name}>>"
        end

        out << " (#{location})"
      end
    end

    class Attr < Symbol
      extend T::Sig

      sig { returns(String) }
      attr_reader :kind

      sig { returns(String) }
      attr_reader :name

      sig { params(location: Location, kind: String, name: String).void }
      def initialize(location, kind, name)
        super(location)

        @kind = kind
        @name = name
      end

      sig { returns(String) }
      def to_s
        "#{kind} #{name}"
      end
    end

    class Method < Symbol
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { params(location: Location, name: String).void }
      def initialize(location, name)
        super(location)

        @name = name
      end

      sig { returns(String) }
      def to_s
        "def #{name} (#{location})"
      end
    end

    class Prop < Symbol
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(String) }
      attr_reader :type

      sig { returns(T::Boolean) }
      attr_reader :read_only

      sig { returns(T::Boolean) }
      attr_reader :has_default

      sig do
        params(
          location: Location,
          name: String,
          type: String,
          read_only: T::Boolean,
          has_default: T::Boolean,
        ).void
      end
      def initialize(location, name, type, read_only:, has_default:)
        super(location)

        @name = name
        @type = type
        @read_only = read_only
        @has_default = has_default
      end

      sig { returns(String) }
      def to_s
        if read_only
          "const #{name}: #{type} (#{location})"
        else
          "prop #{name}: #{type} (#{location})"
        end
      end
    end

    class << self
      extend T::Sig

      sig { params(models: T::Array[Model]).returns(Model) }
      def merge(models)
        model = Model.new
        models.each do |other|
          model.scopes.merge!(other.scopes) { |_k, v1, v2| v1 + v2 }
        end
        model
      end
    end

    sig { returns(T::Hash[String, T::Array[Scope]]) }
    attr_reader :scopes

    sig { void }
    def initialize
      @scopes = T.let({}, T::Hash[String, T::Array[Scope]])
    end

    sig { params(klass: Class).void }
    def add_class(klass)
      (@scopes[klass.full_name] ||= []) << klass
    end

    sig { params(mod: Module).void }
    def add_module(mod)
      (@scopes[mod.full_name] ||= []) << mod
    end

    sig { void }
    def resolve_ancestors!
      @scopes.each_value do |scopes|
        scopes.each do |scope|
          case scope
          when Class
            resolve_superclass(scope)
            resolve_includes(scope)
          when Module
            resolve_includes(scope)
          end
        end
      end
    end

    sig { params(klass: Class).void }
    def resolve_superclass(klass)
      superclass_ref = klass.superclass
      return unless superclass_ref.is_a?(Ref)

      superclass = resolve_name(superclass_ref.full_name, klass)
      klass.superclass = superclass if superclass.is_a?(Class)
    end

    sig { params(scope: Scope).void }
    def resolve_includes(scope)
      scope.includes.each do |inc|
        next unless inc.is_a?(Ref)

        included = resolve_name(inc.full_name, scope)
        scope.includes << included if included.is_a?(Module)
      end
    end

    sig { params(name: String, context: Scope).returns(T.nilable(Scope)) }
    def resolve_name(name, context)
      # 1. Look by fully qualified name directly
      if name.start_with?("::")
        target = T.let(@scopes[name]&.first, T.nilable(Scope))
        return target if target
      end

      # 2. Look inside the parent namespaces
      namespaces = context.full_name.split("::")
      until namespaces.empty?
        full_name = namespaces.join("::") + "::" + name
        target = @scopes[full_name]&.first
        return target if target

        namespaces.pop
      end

      # 3. Look inside the global namespace
      @scopes[name]&.first
    end

    sig { returns(T::Hash[String, T::Array[Class]]) }
    def classes
      classes = T.let({}, T::Hash[String, T::Array[Class]])

      @scopes.each do |full_name, scopes|
        scopes.each do |scope|
          next unless scope.is_a?(Class)

          (classes[full_name] ||= []) << scope
        end
      end

      classes
    end

    sig { returns(T::Hash[String, T::Array[Module]]) }
    def modules
      classes = T.let({}, T::Hash[String, T::Array[Module]])

      @scopes.each do |full_name, scopes|
        scopes.each do |scope|
          next unless scope.is_a?(Module)

          (classes[full_name] ||= []) << scope
        end
      end

      classes
    end

    sig { params(class_name: String).returns(T::Array[Class]) }
    def subclasses_of(class_name)
      subclasses = T.let([], T::Array[Class])

      classes.each do |_full_name, classes|
        classes.each do |klass|
          subclasses << klass if klass.subclass_of?(class_name)
        end
      end

      subclasses
    end

    sig { params(scope_full_name: String).returns(T::Array[Scope]) }
    def descendants_of(scope_full_name)
      descendants = T.let([], T::Array[Scope])

      scopes.each do |_full_name, scopes|
        scopes.each do |scope|
          descendants << scope if scope.descendant_of?(scope_full_name)
        end
      end

      descendants
    end
  end
end
