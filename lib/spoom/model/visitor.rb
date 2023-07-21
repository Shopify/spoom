# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class Visitor
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { params(entity: T.any(Model, Ref, Symbol)).void }
      def visit(entity)
        entity.accept(self)
      end

      sig { params(symbols: T::Array[Symbol]).void }
      def visit_all(symbols)
        symbols.each { |symbol| visit(symbol) }
      end

      sig { params(model: Model).void }
      def visit_model(model)
        model.scopes.keys.sort.each do |full_name|
          model.scopes[full_name]&.each { |scope| visit(scope) }
        end
      end

      sig { params(ref: Ref).void }
      def visit_ref(ref)
        # no-op
      end

      # Scopes

      sig { params(symbol: Class).void }
      def visit_class(symbol)
        symbol.attrs.each { |attr| visit(attr) }
        symbol.defs.each { |defn| visit(defn) }
        symbol.props.each { |incl| visit(incl) }
      end

      sig { params(symbol: Module).void }
      def visit_module(symbol)
        symbol.attrs.each { |attr| visit(attr) }
        symbol.defs.each { |defn| visit(defn) }
        symbol.props.each { |incl| visit(incl) }
      end

      # Properties

      sig { params(symbol: Attr).void }
      def visit_attr(symbol)
        # no-op
      end

      sig { params(symbol: Method).void }
      def visit_method(symbol)
        # no-op
      end

      sig { params(symbol: Prop).void }
      def visit_prop(symbol)
        # no-op
      end
    end

    sig { params(visitor: Visitor).void }
    def accept(visitor)
      visitor.visit_model(self)
    end

    class Ref
      sig { override.params(visitor: Visitor).void }
      def accept(visitor)
        visitor.visit_ref(self)
      end
    end

    class Symbol
      sig { abstract.params(visitor: Visitor).void }
      def accept(visitor); end
    end

    class Class
      sig { override.params(visitor: Visitor).void }
      def accept(visitor)
        visitor.visit_class(self)
      end
    end

    class Module
      sig { override.params(visitor: Visitor).void }
      def accept(visitor)
        visitor.visit_module(self)
      end
    end

    class Attr
      sig { override.params(visitor: Visitor).void }
      def accept(visitor)
        visitor.visit_attr(self)
      end
    end

    class Method
      sig { override.params(visitor: Visitor).void }
      def accept(visitor)
        visitor.visit_method(self)
      end
    end

    class Prop
      sig { override.params(visitor: Visitor).void }
      def accept(visitor)
        visitor.visit_prop(self)
      end
    end
  end
end
