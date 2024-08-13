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
  end

  class Resolver < Model::NamespaceVisitor
    extend T::Sig

    include Spoom::Colorize

    sig { returns(T::Hash[Prism::Node, RBI::Type]) }
    attr_reader :node_types

    class Scope
      extend T::Sig

      sig { returns(T::Hash[String, RBI::Type]) }
      attr_reader :var_types

      sig { void }
      def initialize
        @var_types = T.let({}, T::Hash[String, RBI::Type])
      end
    end

    sig { params(model: Model, file: String).void }
    def initialize(model, file)
      super()

      @model = model
      @file = file
      @scope_stack = T.let([Scope.new], T::Array[Scope])
      @node_types = T.let({}, T::Hash[Prism::Node, RBI::Type])
      @alive_types = T.let({}, T::Hash[String, RBI::Type])
      @in_method_def = T.let(false, T::Boolean)
    end

    sig { override.params(node: T.nilable(Prism::Node)).void }
    def visit(node)
      super
      # puts "node: #{node.slice.lines.first} #: #{@node_types[node]}"
    end

    sig { override.params(node: Prism::DefNode).void }
    def visit_def_node(node)
      @in_method_def = true
      method = resolve_method_for_type(self_type, node.name.to_s)&.first
      scope = Scope.new
      node.parameters&.child_nodes&.compact&.each do |param|
        case param
        when Prism::RequiredParameterNode
          if method
            sig = method.sigs.first&.to_rbi
            if sig
              param_type = sig.params.find { |p| p.name == param.name.to_s }&.type
              scope.var_types[param.name.to_s] = case param_type
              when String
                type(param_type)
              when RBI::Type
                param_type
              else
                RBI::Type.untyped
              end
            end
          end
        end
      end
      @scope_stack << scope
      super
      @scope_stack.pop

      body = node.body
      body_return_type = type("void")
      body_return_type = @node_types[body] || type("void") if body
      if method
        sig = method.sigs.first
        sig_return_type = sig.to_rbi.return_type if sig
      end

      if sig_return_type && sig_return_type != body_return_type
        unless @file.end_with?(".rbi")
          # $stderr.puts "error: return type mismatch, expected #{sig_return_type}, got #{body_return_type}"
        end
      end

      # puts "def: #{node.name} -> #{sig_return_type}:#{body_return_type}"

      @node_types[node] = type("Symbol")
      @in_method_def = false
    end

    sig { override.params(node: Prism::IntegerNode).void }
    def visit_integer_node(node)
      @node_types[node] = type("Integer")
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
      @node_types[node] = RBI::Type.any(if_type, else_type)
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
      puts "visit_call_node: #{node.name}"
      return if ignored_call?(node.name)

      @node_types[node] = RBI::Type.untyped

      super

      recv = node.receiver
      recv_type = if recv.nil? || recv.is_a?(Prism::SelfNode)
        self_type
      elsif recv.is_a?(Prism::ConstantReadNode) || recv.is_a?(Prism::ConstantPathNode)
        RBI::Type.class_of(T.cast(type(recv.slice), RBI::Type::Simple))
      else
        type_for(recv)
      end
      puts "recv_type: #{recv_type}"
      if recv_type == RBI::Type.self_type
        recv_type = if recv
          @node_types[recv] || RBI::Type.untyped
        else
          RBI::Type.untyped
        end
      end

      if recv_type != RBI::Type.untyped
        methods = resolve_method_for_type(recv_type, node.name.to_s)
        method = methods&.first
        unless method
          error(node_location(node), "method `#{node.name}` not found for type `#{self_type}`")
          @node_types[node] = RBI::Type.untyped
          return
        end
        sig = method.sigs.first
        unless sig
          # error(node_location(node), "`sig` not found for `#{method.full_name}`")
          return
        end

        puts "sig: #{sig.string}"
        sig = reify_signature(recv_type, sig)
        puts "sig: #{sig.string}"

        return_type = sig.return_type
        return_type = type(return_type)
        @node_types[node] = return_type
      end
    end

    sig { params(node: Prism::Node).returns(Location) }
    def node_location(node)
      Spoom::Location.from_prism(@file, node.location)
    end

    sig { params(location: Location, message: String).void }
    def error(location, message)
      error = set_color("error", Color::RED)
      $stderr.puts "#{location.file}:#{location.start_line}:#{location.start_column}: #{error}: #{message}"
      $stderr.puts
      lines = location.snippet(lines_around: 2).lines
      lines.each do |line|
        $stderr.puts "    #{set_color(line, Color::LIGHT_BLACK)}"
      end
    end

    private

    sig { returns(Scope) }
    def current_scope
      T.must(@scope_stack.last)
    end

    sig { returns(RBI::Type) }
    def self_type
      return type("Object") if @names_nesting.empty?

      current_type = type(@names_nesting.join("::"))

      if @in_method_def
        current_type
      else
        RBI::Type.class_of(T.cast(current_type, RBI::Type::Simple))
      end
    end

    sig { params(type: T.any(String, RBI::Type)).returns(RBI::Type) }
    def type(type)
      return type if type.is_a?(RBI::Type)

      @alive_types[type] ||= RBI::Type.parse_string(type)
    end

    sig { params(node: T.nilable(Prism::Node)).returns(RBI::Type) }
    def type_for(node)
      return RBI::Type.untyped unless node

      case node
      when Prism::IntegerNode
        RBI::Type.simple("Integer")
      when Prism::StringNode
        RBI::Type.simple("String")
      when Prism::SymbolNode
        RBI::Type.simple("Symbol")
      when Prism::LocalVariableReadNode
        current_scope.var_types[node.name.to_s] || RBI::Type.untyped
      else
        @node_types[node] || RBI::Type.untyped
      end
    end

    class CallSite
      extend T::Sig

      sig { returns(RBI::Type) }
      attr_reader :recv_type

      sig { returns(Symbol) }
      attr_reader :name

      sig { returns(Model::Symbol) }
      attr_reader :method

      sig { params(recv_type: RBI::Type, name: Symbol, method: Model::Symbol).void }
      def initialize(recv_type, name, method)
        @recv_type = recv_type
        @name = name
        @method = method
      end

      sig { returns(T::Array[Model::Method]) }
      def method_definitions
        @method.definitions.grep(Model::Method)
      end

      sig { returns(T.nilable(RBI::Sig)) }
      def sig
        sigs.first
      end

      sig { returns(T::Array[RBI::Sig]) }
      def sigs
        method_definitions.flat_map(&:sigs).map(&:to_rbi)
      end
    end

    # resolver job
    #   enqueue
    #   resolve(Name, Body, Type, ...)
    # resolve call
    # - resolve receiver type
    # - resolve method
    # - reify signature

    sig { params(type: RBI::Type, name: String).returns(T.nilable(T::Array[Model::Method])) }
    def resolve_method_for_type(type, name)
      puts "resolve_method_for_type: #{type} #{name}"
      case type
      when RBI::Type.untyped
        []
      when RBI::Type::ClassOf
        inner_type = type.type
        type_symbol = @model.symbols[inner_type.to_rbi]
        raise "unknown symbol for type #{inner_type.to_rbi}" unless type_symbol

        defs = type_symbol.definitions.grep(Model::Namespace).flat_map(&:children).grep(Model::Method)
        defs.select! { |m| m.name == name }
        defs.select!(&:singleton?)
        return defs if defs.any?

        symbols = @model.supertypes(type_symbol)
        class_symbol = @model.symbols["Class"]

        if class_symbol
          symbols = [*symbols, class_symbol, *@model.supertypes(class_symbol)]
        end

        puts " symbols: #{symbols.map(&:full_name).join(", ")}"
        defs = symbols.flat_map(&:definitions).grep(Model::Namespace).flat_map(&:children).grep(Model::Method)
        puts " defs: #{defs.map(&:full_name).join(", ")}"
        defs.select! { |m| m.name == name }

        defs
      when RBI::Type::Simple
        type_symbol = @model.symbols[type.to_rbi]
        raise "unknown symbol for type #{type.to_rbi}" unless type_symbol

        symbols = [type_symbol, *@model.supertypes(type_symbol)]
        puts " symbols: #{symbols.map(&:full_name).join(", ")}"

        defs = symbols.flat_map(&:definitions).grep(Model::Namespace).flat_map(&:children).grep(Model::Method)
        defs.select! { |m| m.name == name }
        # defs.select!(&:singleton?) if singleton_context

        # TODO: linearize results properly
        defs
      else
        raise "unexpected type: #{type}"
      end
    end

    sig { params(recv_type: RBI::Type, sig: Model::Sig).returns(RBI::Sig) }
    def reify_signature(recv_type, sig)
      sig = sig.to_rbi
      sig.return_type = type(sig.return_type) if sig.return_type.is_a?(String)
      if sig.return_type == RBI::Type.self_type
        sig.return_type = recv_type
      end
      if sig.return_type == RBI::Type.attached_class
        raise unless recv_type.is_a?(RBI::Type::ClassOf)

        sig.return_type = recv_type.type
      end
      sig
    end

    IGNORED_CALLS = [
      :private,
      :public,
      :protected,
      :sig,
    ]

    sig { params(name: Symbol).returns(T::Boolean) }
    def ignored_call?(name)
      IGNORED_CALLS.include?(name)
    end
  end
end
