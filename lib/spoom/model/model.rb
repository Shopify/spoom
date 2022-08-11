# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    extend T::Sig

    class Loc
    end

    class Symbol
      extend T::Sig
      extend T::Helpers

      abstract!

      sig do
        params(
          document_symbol: Spoom::LSP::DocumentSymbol,
          parent_scope: T.nilable(Scope)
        ).returns(T.nilable(Symbol))
      end
      def self.from_document_symbol(document_symbol, parent_scope:)
        name = document_symbol.name
        return nil if name.empty? || name.match?(/^<.*>$/)

        kind = Spoom::LSP::DocumentSymbol::SYMBOL_KINDS[document_symbol.kind]
        return nil unless kind

        case kind
        when "module", "class"
          Scope.new(name, parent_scope: parent_scope)
        when "const"
          Const.new(name, parent_scope: parent_scope)
        when "constructor", "def", "field"
          Prop.new(name, parent_scope: parent_scope)
        else
          raise "Unknown symbol kind: #{kind}"
        end
      end

      sig { returns(String) }
      attr_reader :name

      sig { returns(T.nilable(Scope)) }
      attr_reader :parent_scope

      sig { returns(T.nilable(String)) }
      attr_accessor :sig_string

      sig { returns(T.nilable(String)) }
      attr_accessor :comment_string

      sig do
        params(
          name: String,
          parent_scope: T.nilable(Scope),
          sig_string: T.nilable(String),
          comment_string: T.nilable(String)
        ).void
      end
      def initialize(name, parent_scope: nil, sig_string: nil, comment_string: nil)
        @name = name
        @parent_scope = parent_scope
        parent_scope.symbols << self if parent_scope
        @sig_string = sig_string
        @comment_string = comment_string
      end

      sig { abstract.returns(String) }
      def fully_qualified_name; end

      sig { override.returns(String) }
      def to_s
        fully_qualified_name
      end
    end

    class File
      extend T::Sig

      sig { returns(T::Set[Symbol]) }
      attr_reader :symbols

      sig { returns(String) }
      attr_reader :path

      sig { params(path: String).void }
      def initialize(path)
        @path = path
        @symbols = T.let(Set.new, T::Set[Symbol])
      end

      sig { override.returns(String) }
      def to_s
        path
      end
    end

    class Scope < Symbol
      extend T::Sig

      sig { params(name: String, parent_scope: T.nilable(Scope)).void }
      def initialize(name, parent_scope: nil)
        super(name, parent_scope: parent_scope)
        @symbols = T.let([], T::Array[Symbol])
      end

      sig { override.returns(String) }
      def fully_qualified_name
        return name if name.start_with?("::")

        "#{parent_scope&.fully_qualified_name}::#{name}"
      end

      sig { returns(T::Array[Scope]) }
      def namespace
        symbols = T.let([], T::Array[Scope])
        symbols << self
        parent = T.let(parent_scope, T.nilable(Scope))
        while parent
          symbols << parent
          parent = parent.parent_scope
        end
        symbols.reverse
      end

      sig { params(kind: T.nilable(T.class_of(Symbol))).returns(T::Array[Symbol]) }
      def symbols(kind = nil)
        return @symbols unless kind

        @symbols.select { |s| s.is_a?(kind) }
      end
    end

    class Const < Symbol
      sig { override.returns(String) }
      def fully_qualified_name
        scope = parent_scope
        return name unless scope

        "#{parent_scope&.fully_qualified_name}::#{name}"
      end
    end

    class Prop < Symbol
      sig { override.returns(String) }
      def fully_qualified_name
        scope = parent_scope
        return name unless scope

        "#{parent_scope&.fully_qualified_name}##{name}"
      end
    end

    module Builder
      class LSP
        extend T::Sig

        sig { params(exec_path: String, client: Spoom::LSP::Client, files: T::Array[String]).returns(Model) }
        def self.build_model(exec_path, client, files)
          builder = LSP.new(exec_path, client, files)
          builder.build_model!
          builder.model
        end

        sig { returns(Model) }
        attr_reader :model

        sig { params(exec_path: String, client: Spoom::LSP::Client, files: T::Array[String]).void }
        def initialize(exec_path, client, files)
          @exec_path = exec_path
          @client = client
          @files = files
          @model = T.let(Model.new, Model)
          @scopes_stack = T.let([], T::Array[Scope])
          @current_file = T.let(nil, T.nilable(File))
        end

        sig { void }
        def build_model!
          @files.each do |file|
            visit_file(file)
          end
        end

        private

        sig { params(path: String).void }
        def visit_file(path)
          puts "visit_file: #{path}"
          return if @model.files.key?(path)
          return if path.start_with?("test/")
          return if path.start_with?("sorbet/")
          return if path.end_with?(".rbi")

          file = File.new(path)
          @current_file = file
          @model.files[path] = file
          uri = to_uri(file.path)
          roots = @client.document_symbols(uri)
          return if roots.empty?

          visit_document_symbols(roots)
        end

        sig { params(document_symbols: T::Array[Spoom::LSP::DocumentSymbol]).void }
        def visit_document_symbols(document_symbols)
          document_symbols.each do |document_symbol|
            visit_document_symbol(document_symbol)
          end
        end

        sig { params(document_symbol: Spoom::LSP::DocumentSymbol).void }
        def visit_document_symbol(document_symbol)
          last_scope = @scopes_stack.last

          loc = document_symbol.range
          unless loc
            visit_document_symbols(document_symbol.children)
            return
          end

          symbol = Symbol.from_document_symbol(document_symbol, parent_scope: last_scope)
          unless symbol
            visit_document_symbols(document_symbol.children)
            return
          end

          if @current_file && !last_scope
            @current_file.symbols << symbol
          end
          @model.symbols << symbol

          case symbol
          when Scope
            symbols_for_name = @model.scopes[symbol.fully_qualified_name] ||= []
            symbols_for_name << symbol
            @scopes_stack.push(symbol)
            visit_document_symbols(document_symbol.children)
            @scopes_stack.pop
          when Prop
            props_for_name = @model.props[symbol.fully_qualified_name] ||= []
            props_for_name << symbol
            visit_document_symbols(document_symbol.children)
          else
            visit_document_symbols(document_symbol.children)
          end

          uri = to_uri(T.must(@current_file).path)

          hover_string = @client.hover(uri, loc.start.line, loc.start.char)&.contents
          if hover_string
            hover_sections = hover_string.split("\n---\n", 2)
            symbol.sig_string = hover_sections.first
            if hover_sections.size > 1
              symbol.comment_string = hover_sections.last
            end
          end
        end

        sig { params(path: String).returns(String) }
        def to_uri(path)
          "file://" + ::File.absolute_path(path)
        end
      end
    end

    sig { returns(T::Hash[String, File]) }
    attr_reader :files

    sig { returns(T::Set[Symbol]) }
    attr_reader :symbols

    sig { returns(T::Hash[String, T::Array[Scope]]) }
    attr_reader :scopes

    sig { returns(T::Hash[String, T::Array[Prop]]) }
    attr_reader :props

    sig { void }
    def initialize
      @files = T.let({}, T::Hash[String, File])
      @symbols = T.let(Set.new, T::Set[Symbol])
      @scopes = T.let({}, T::Hash[String, T::Array[Scope]])
      @props = T.let({}, T::Hash[String, T::Array[Prop]])
    end

    sig { override.returns(String) }
    def to_s
      super
    end

    sig { override.returns(String) }
    def inspect
      to_s
    end
  end
end
