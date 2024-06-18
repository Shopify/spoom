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
      end

      # Indexing

      sig { params(definition: Definition).void }
      def define(definition)
        (@definitions[definition.name] ||= []) << definition
      end

      sig { params(reference: Reference).void }
      def reference(reference)
        (@references[reference.name] ||= []) << reference
      end

      # Mark all definitions having a reference of the same name as `alive`
      #
      # To be called once all the files have been indexed and all the definitions and references discovered.
      sig { params(plugins: T::Array[Plugins::Base]).void }
      def finalize!(plugins: [])
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
              define(definition)
              plugins.each { |plugin| plugin.internal_on_define_class(symbol_def, definition) }
            when Model::Module
              definition = Definition.new(
                kind: Definition::Kind::Module,
                name: symbol.name,
                full_name: symbol.full_name,
                location: symbol_def.location,
              )
              define(definition)
              plugins.each { |plugin| plugin.internal_on_define_module(symbol_def, definition) }
            end
          end
        end
        @references.keys.each do |name|
          definitions_for_name(name).each(&:alive!)
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
