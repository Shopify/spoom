# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Index
      extend T::Sig

      sig { returns(T::Hash[String, T::Array[Definition]]) }
      attr_reader :definitions

      sig { returns(T::Hash[String, T::Array[Reference]]) }
      attr_reader :references

      sig { void }
      def initialize
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
      sig { void }
      def finalize!
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
