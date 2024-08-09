# typed: strict
# frozen_string_literal: true

require "rbi"

module Spoom
  class Model
    extend T::Sig

    sig { params(symbol: Model::Symbol, name: String).returns(T.nilable(T::Array[Method])) }
    def resolve_method_from_symbol(symbol, name)
      namespace = symbol.definitions.grep(Model::Namespace).first
      raise unless namespace

      defs = namespace.children.grep(Model::Method).select { |m| m.name == name }

      if defs.empty?
        ancestors = supertypes(symbol)
        # puts ancestors.inspect
        defs = ancestors.flat_map { |a| a.definitions.grep(Model::Method).select { |m| m.name == name } }
      end

      defs
    end

    sig { params(type: String, name: String).returns(T.nilable(T::Array[Method])) }
    def resolve_method(type, name)
      puts "resolve_method: #{type}##{name}"
      symbol = type

      type_symbol = @symbols[type]
      return [] unless type_symbol

      puts "type_symbol: #{type_symbol.full_name}"

      namespace = type_symbol.definitions.grep(Model::Namespace).first
      # raise unless namespace
      return [] unless namespace

      defs = namespace.children.grep(Model::Method).select { |m| m.name == name }

      if defs.empty?
        ancestors = supertypes(type_symbol)
        # puts ancestors.inspect
        defs = ancestors.flat_map { |a| a.definitions.grep(Model::Method).select { |m| m.name == name } }
      end

      puts defs.size

      defs
    end
  end

  class Resolver < Model::NamespaceVisitor
    extend T::Sig

    class Scope
      extend T::Sig

      sig { returns(T::Hash[String, String]) }
      attr_reader :var_types

      sig { void }
      def initialize
        @var_types = T.let({}, T::Hash[String, String])
      end
    end

    sig { params(model: Model, file: String).void }
    def initialize(model, file)
      super()

      @model = model
      @file = file
      @scope_stack = T.let([Scope.new], T::Array[Scope])
      @node_types = T.let({}, T::Hash[Prism::Node, String])
    end

    sig { override.params(node: T.nilable(Prism::Node)).void }
    def visit(node)
      super
      # puts "node: #{node.slice.lines.first} #: #{@node_types[node]}"
    end

    sig { override.params(node: Prism::DefNode).void }
    def visit_def_node(node)
      method = @model.resolve_method(self_type, node.name.to_s)&.first
      scope = Scope.new
      node.parameters&.child_nodes&.compact&.each do |param|
        case param
        when Prism::RequiredParameterNode
          if method
            sig = method.sigs.first&.to_rbi
            if sig
              param_type = sig.params.find { |p| p.name == param.name.to_s }&.type
              if param_type
                scope.var_types[param.name.to_s] = param_type
              end
            end
          end
        end
      end
      @scope_stack << scope
      super
      @scope_stack.pop

      body = node.body
      body_return_type = "void"
      if body
        body_return_type = @node_types[body] || "void"
      end
      if method
        sig = method.sigs.first
        if sig
          sig_return_type = sig.to_rbi.return_type
        end
      end

      if sig_return_type && sig_return_type != body_return_type
        unless @file.end_with?(".rbi")
          # $stderr.puts "error: return type mismatch, expected #{sig_return_type}, got #{body_return_type}"
        end
      end

      # puts "def: #{node.name} -> #{sig_return_type}:#{body_return_type}"

      @node_types[node] = "Symbol"
    end

    sig { override.params(node: Prism::IntegerNode).void }
    def visit_integer_node(node)
      @node_types[node] = "Integer"
    end

    sig { override.params(node: Prism::StatementsNode).void }
    def visit_statements_node(node)
      super

      last = node.body.last
      @node_types[node] = type_for(last)
    end

    sig { override.params(node: Prism::IfNode).void }
    def visit_if_node(node)
      super

      if_type = type_for(node.statements)
      else_type = type_for(node.consequent)
      @node_types[node] = "T.any(#{if_type}, #{else_type})"
    end

    sig { override.params(node: Prism::LocalVariableWriteNode).void }
    def visit_local_variable_write_node(node)
      super

      assign_type = type_for(node.value)
      current_scope.var_types[node.name.to_s] = assign_type
      @node_types[node] = assign_type
    end

    sig { override.params(node: Prism::CallNode).void }
    def visit_call_node(node)
      return if node.name == :sig

      @node_types[node] = "untyped"

      super

      recv = node.receiver
      recv_type = if recv.nil? || recv.is_a?(Prism::SelfNode)
        self_type
      else
        type_for(recv)
      end
      if recv_type != "untyped"
        methods = @model.resolve_method(recv_type, node.name.to_s)
        method = methods&.first
        unless method
          $stderr.puts "error: method not found: #{node.name} for type #{self_type}"
          @node_types[node] = "untyped"
          return
        end
        sig = method.sigs.first
        unless sig
          $stderr.puts "error: sig not found for #{method.full_name}"
          return
        end
        @node_types[node] = sig.to_rbi.return_type || "untyped"
      end
    end

    private

    sig { returns(Scope) }
    def current_scope
      T.must(@scope_stack.last)
    end

    sig { returns(String) }
    def self_type
      if @names_nesting.empty?
        return "Object"
      end

      @names_nesting.join("::")
    end

    sig { params(node: T.nilable(Prism::Node)).returns(String) }
    def type_for(node)
      return "untyped" unless node

      case node
      when Prism::IntegerNode
        "Integer"
      when Prism::StringNode
        "String"
      when Prism::SymbolNode
        "Symbol"
      when Prism::LocalVariableReadNode
        current_scope.var_types[node.name.to_s] || "untyped"
      else
        @node_types[node] || "untyped"
      end
    end
  end
end
