# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    extend T::Sig

    class Loc
    end

    class Symbol
      extend T::Sig

      sig { params(document_symbol: Spoom::LSP::DocumentSymbol).returns(T.nilable(Symbol)) }
      def self.from_document_symbol(document_symbol)
        name = document_symbol.name
        return nil if name.empty? || name.match?(/^<.*>$/)

        kind = Spoom::LSP::DocumentSymbol::SYMBOL_KINDS[document_symbol.kind]
        return nil unless kind

        case kind
        when "module", "class"
          Scope.new(name)
        when "def"
          Prop.new(name)
        end
      end

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String).void }
      def initialize(name)
        @name = name
      end
    end

    class Scope < Symbol
    end

    class Prop < Symbol
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
        end

        sig { void }
        def build_model!
          @files.each do |file|
            visit_file(file)
          end
        end

        private

        sig { params(file: String).void }
        def visit_file(file)
          return if @model.files.include?(file)
          return if file.start_with?("test/")
          return if file.start_with?("sorbet/")
          return if file.end_with?(".rbi")

          @model.files << file
          uri = to_uri(file)
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
          symbol = Symbol.from_document_symbol(document_symbol)

          if symbol
            @model.symbols << symbol

            case symbol
            when Scope
              @model.scopes << symbol
            when Prop
              @model.props << symbol
            end

            # hover = @client.hover(@uri, loc.start.line, loc.start.char)
          end

          visit_document_symbols(document_symbol.children)
        end

        sig { params(path: String).returns(String) }
        def to_uri(path)
          "file://" + File.join(File.expand_path(@exec_path), path)
        end
      end
    end

    sig { returns(T::Set[String]) }
    attr_reader :files

    sig { returns(T::Set[Symbol]) }
    attr_reader :symbols

    sig { returns(T::Set[Scope]) }
    attr_reader :scopes

    sig { returns(T::Set[Prop]) }
    attr_reader :props

    sig { void }
    def initialize
      @files = T.let(Set.new, T::Set[String])
      @symbols = T.let(Set.new, T::Set[Symbol])
      @scopes = T.let(Set.new, T::Set[Scope])
      @props = T.let(Set.new, T::Set[Prop])
    end
  end
end
