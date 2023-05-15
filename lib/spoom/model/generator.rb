# typed: strict
# frozen_string_literal: true

module Spoom
  module Model
    class Generator
      extend T::Sig

      UPPERCASE_LETTERS = T.let(("A".."Z").to_a.freeze, T::Array[String])
      LOWERCASE_LETTERS = T.let(("a".."z").to_a.freeze, T::Array[String])

      sig { returns(Integer) }
      attr_reader :generated_classes

      sig { void }
      def initialize
        @generated_files = T.let(0, Integer)
        @generated_classes = T.let(0, Integer)
      end

      sig { params(context: Context, files: Integer).void }
      def generate_files(context, files)
        @generated_files += 1

        files.times do
          name = generate_file_name
          root = generate_class

          context.write!(name, root.string)
        end
      end

      sig { params(depth: Integer).returns(Class) }
      def generate_class(depth: 0)
        @generated_classes += 1

        node = Class.new(generate_scope_name)
        return node if depth > 3

        rand(0..10).times do
          node << generate_class(depth: depth + 1)
        end
        node
      end

      sig { returns(String) }
      def generate_file_name
        name = String.new
        name << T.cast(LOWERCASE_LETTERS.sample(rand(1..10)), T::Array[String]).join
        name << ".rb"
        name
      end

      sig { returns(String) }
      def generate_scope_name
        name = String.new
        name << UPPERCASE_LETTERS.sample
        name << T.cast(LOWERCASE_LETTERS.sample(rand(1..10)), T::Array[String]).join
        name
      end
    end
  end
end
