# typed: strict
# frozen_string_literal: true

module Spoom
  module Docs
    module Templates
      class Template
        extend T::Sig
        extend T::Helpers

        # Create a new template from an Erb file path
        sig { params(template: String).void }
        def initialize(template)
          @template = template
        end

        sig { returns(String) }
        def erb
          File.read(@template)
        end

        sig { returns(String) }
        def html
          ERB.new(erb).result(get_binding)
        end

        sig { returns(Binding) }
        def get_binding # rubocop:disable Naming/AccessorMethodName
          binding
        end

        sig { params(path: String).returns(String) }
        def link_for_file(path)
          "docs/files/#{path}.html"
        end

        sig { params(qname: String).returns(String) }
        def link_for_scope(qname)
          "./#{qname}.html"
        end

        sig { params(qname: String).returns(String) }
        def link_for_prop(qname)
          "docs/props/#{qname}.html"
        end

        sig { params(symbol: Spoom::Model::Symbol).returns(String) }
        def anchor_to_symbol(symbol)
          "##{symbol.name}"
        end

        sig { params(symbol: Spoom::Model::Symbol, anchor: T::Boolean).returns(String) }
        def link_to_symbol(symbol, anchor: false)
          case symbol
          when Spoom::Model::Scope
            link_for_scope(symbol.fully_qualified_name)
          when Spoom::Model::Prop
            # TODO: handle top level
            parent_scope = T.must(symbol.parent_scope)
            "#{link_to_symbol(parent_scope)}##{symbol.name}"
          else
            raise "Unknown symbol type #{symbol.class}"
          end
        end

        sig do
          params(
            symbol: Spoom::Model::Symbol,
            anchor: T::Boolean,
            qualified_name: T::Boolean
          ).returns(Templates::SymbolLink)
        end
        def symbol_link(symbol, anchor: false, qualified_name: true)
          Templates::SymbolLink.new(symbol, anchor: anchor, qualified_name: qualified_name)
        end

        sig { params(symbol: Spoom::Model::Symbol).returns(Templates::SymbolCard) }
        def symbol_card(symbol)
          Templates::SymbolCard.new(symbol)
        end
      end

      class Page < Template
        extend T::Sig

        sig { returns(Pages::Base) }
        attr_reader :body

        sig { params(body: Pages::Base).void }
        def initialize(body)
          super("#{Spoom::SPOOM_PATH}/templates/docs/page.erb")
          @body = body
        end

        sig { returns(Template) }
        def header
          Template.new("#{Spoom::SPOOM_PATH}/templates/docs/partials/header.erb")
        end

        sig { returns(Template) }
        def footer
          Template.new("#{Spoom::SPOOM_PATH}/templates/docs/partials/footer.erb")
        end

        sig { params(path: String).void }
        def write!(path)
          dir = ::File.dirname(path)
          FileUtils.mkdir_p(dir)
          ::File.write(path, html)
        end
      end

      module Pages
        class Base < Template
          extend T::Helpers

          abstract!

          sig { abstract.returns(String) }
          def title; end
        end

        class Index < Base
          extend T::Sig

          sig { returns(Model) }
          attr_reader :model

          sig { params(model: Model).void }
          def initialize(model)
            super("#{Spoom::SPOOM_PATH}/templates/docs/pages/index.erb")
            @model = model
          end

          sig { override.returns(String) }
          def title
            "Index"
          end

          sig { returns(T::Array[String]) }
          def files_links
            @model.files.keys.sort.map do |path|
              "<a href='../#{link_for_file(path)}'>#{path}</a>"
            end
          end

          sig { returns(T::Array[String]) }
          def scopes_links
            @model.scopes.keys.sort.map do |name|
              "<a href='#{link_for_scope(name)}'>#{name}</a>"
            end
          end

          sig { returns(T::Array[String]) }
          def props_links
            @model.props.keys.sort.map do |name|
              "<a href='#{link_for_prop(name)}'>#{name}</a>"
            end
          end
        end

        class FileSymbols < Base
          extend T::Sig

          sig { returns(Spoom::Model::File) }
          attr_reader :file

          sig { params(file: Spoom::Model::File).void }
          def initialize(file)
            super("#{Spoom::SPOOM_PATH}/templates/docs/pages/file_symbols.erb")
            @file = file
          end

          sig { override.returns(String) }
          def title
            @file.path
          end
        end

        class Scope < Base
          extend T::Sig

          sig { params(fully_qualified_name: String, symbols: T::Array[Spoom::Model::Scope]).void }
          def initialize(fully_qualified_name, symbols)
            super("#{Spoom::SPOOM_PATH}/templates/docs/pages/scope.erb")
            @fully_qualified_name = fully_qualified_name
            @symbols = symbols
          end

          sig { override.returns(String) }
          def title
            @fully_qualified_name
          end

          sig { returns(T::Array[Spoom::Model::Scope]) }
          def scope_constants
            @scope_constants ||= T.let(
              T.cast(
                @symbols
                  .map { |symbol| symbol.symbols.select { |child| child.is_a?(Spoom::Model::Scope) } }
                  .flatten
                  .uniq
                  .sort_by(&:fully_qualified_name),
                T::Array[Spoom::Model::Scope]
              ), T.nilable(T::Array[Spoom::Model::Scope])
            )
          end

          sig { returns(T::Array[Spoom::Model::Prop]) }
          def scope_properties
            @scope_properties ||= T.let(
              T.cast(
                @symbols
                  .map { |symbol| symbol.symbols.select { |child| child.is_a?(Spoom::Model::Prop) } }
                  .flatten
                  .uniq
                  .sort_by(&:fully_qualified_name),
                T::Array[Spoom::Model::Prop]
              ), T.nilable(T::Array[Spoom::Model::Prop])
            )
          end
        end
      end

      class SymbolLink < Template
        extend T::Sig

        sig { params(symbol: Spoom::Model::Symbol, anchor: T::Boolean, qualified_name: T::Boolean).void }
        def initialize(symbol, anchor: false, qualified_name: true)
          super("#{Spoom::SPOOM_PATH}/templates/docs/partials/symbol_link.erb")
          @symbol = symbol
          @title = T.let(symbol.comment_string&.lstrip&.lines&.first&.strip, T.nilable(String))

          link = anchor ? anchor_to_symbol(symbol) : link_to_symbol(symbol)
          @link = T.let(link, T.nilable(String))

          name = qualified_name ? symbol.fully_qualified_name : symbol.name
          @text = T.let(name, T.nilable(String))
        end
      end

      class SymbolCard < Template
        extend T::Sig

        sig { params(symbol: Spoom::Model::Symbol).void }
        def initialize(symbol)
          super("#{Spoom::SPOOM_PATH}/templates/docs/symbol_card.erb")
          @symbol = symbol
        end
      end
    end
  end
end
