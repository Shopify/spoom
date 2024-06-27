# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Index
      extend T::Sig

      sig { returns(Model) }
      attr_reader :model

      sig { returns(T::Hash[String, T::Array[Definition]]) }
      attr_reader :definitions

      sig { returns(T::Hash[String, T::Array[Reference]]) }
      attr_reader :references

      sig { params(model: Model).void }
      def initialize(model)
        @model = model
        @definitions = T.let({}, T::Hash[String, T::Array[Definition]])
        @references = T.let({}, T::Hash[String, T::Array[Reference]])
        @ignored = T.let(Set.new, T::Set[Model::SymbolDef])
      end

      # Indexing

      sig { params(definition: Definition).void }
      def define(definition)
        (@definitions[definition.name] ||= []) << definition
      end

      sig { params(name: String, location: Location).void }
      def reference_constant(name, location)
        (@references[name] ||= []) << Reference.new(name: name, kind: Reference::Kind::Constant, location: location)
      end

      sig { params(name: String, location: Location).void }
      def reference_method(name, location)
        (@references[name] ||= []) << Reference.new(name: name, kind: Reference::Kind::Method, location: location)
      end

      sig { params(symbol_def: Model::SymbolDef).void }
      def ignore(symbol_def)
        @ignored << symbol_def
      end

      sig { params(plugins: T::Array[Plugins::Base]).void }
      def apply_plugins!(plugins)
        @model.symbols.each do |_full_name, symbol|
          symbol.definitions.each do |symbol_def|
            case symbol_def
            when Model::Class
              plugins.each { |plugin| plugin.internal_on_define_class(symbol_def) }
            when Model::Module
              plugins.each { |plugin| plugin.internal_on_define_module(symbol_def) }
            when Model::Constant
              plugins.each { |plugin| plugin.internal_on_define_constant(symbol_def) }
            when Model::Method
              plugins.each { |plugin| plugin.internal_on_define_method(symbol_def) }
            when Model::Attr
              plugins.each { |plugin| plugin.internal_on_define_accessor(symbol_def) }
            end
          end
        end
      end

      # Mark all definitions having a reference of the same name as `alive`
      #
      # To be called once all the files have been indexed and all the definitions and references discovered.
      sig { params(exclude_references_from_paths: T::Array[String]).void }
      def finalize!(exclude_references_from_paths: [])
        @model.symbols.each do |_full_name, symbol|
          symbol.definitions.each do |symbol_def|
            case symbol_def
            when Model::Class
              definition = Definition.new(
                kind: Definition::Kind::Class,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::Module
              definition = Definition.new(
                kind: Definition::Kind::Module,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::Constant
              definition = Definition.new(
                kind: Definition::Kind::Constant,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::Method
              definition = Definition.new(
                kind: Definition::Kind::Method,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::AttrAccessor
              definition = Definition.new(
                kind: Definition::Kind::AttrReader,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)

              definition = Definition.new(
                kind: Definition::Kind::AttrWriter,
                name: "#{symbol.name}=",
                full_name: "#{symbol.full_name}=",
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::AttrReader
              definition = Definition.new(
                kind: Definition::Kind::AttrReader,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              definition.alive! if @references.key?(symbol.name)
              define(definition)
            when Model::AttrWriter
              definition = Definition.new(
                kind: Definition::Kind::AttrWriter,
                name: "#{symbol.name}=",
                full_name: "#{symbol.full_name}=",
                location: symbol_def.location,
              )
              definition.ignored! if @ignored.include?(symbol_def)
              references = @references[symbol.name]

              definition.alive! if references && references.any? { |ref| !ref.located_in?(exclude_references_from_paths) }
              define(definition)
            end
          end
        end
      end

      # Utils

      sig { params(name: String).returns(T::Array[Definition]) }
      def definitions_for_name(name)
        @definitions[name] || []
      end

      sig { returns(T::Array[Definition]) }
      def all_definitions
        @definitions.values.flatten
      end

      sig { returns(T::Array[Reference]) }
      def all_references
        @references.values.flatten
      end
    end
  end
end
