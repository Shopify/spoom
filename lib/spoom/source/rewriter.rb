# typed: strict
# frozen_string_literal: true

module Spoom
  # This module provides a simple API to rewrite source code.
  #
  # Using a `Rewriter`, you can build a list of changes to apply to a source file
  # and apply them all at once. Edits are applied from bottom to top, so that the
  # line numbers are not remapped after each edit.
  #
  # The source code is represented as an array of bytes, so that it can be
  # manipulated in place. The client is responsible for `string <-> bytes`
  # conversions and encoding handling.
  #
  # ```ruby
  # bytes = "def foo; end".bytes
  #
  # rewriter = Spoom::Source::Rewriter.new
  # rewriter << Spoom::Source::Replace.new(4, 6, "baz")
  # rewriter << Spoom::Source::Insert.new(0, "def bar; end\n")
  # rewriter.rewrite!(bytes)
  #
  # puts bytes.pack("C*") # => "def bar; end\ndef baz; end"
  # ```
  module Source
    class PositionError < Spoom::Error; end

    # @abstract
    class Edit
      # @abstract
      #: (Array[Integer]) -> void
      def apply(bytes) = raise NotImplementedError, "Abstract method called"

      # @abstract
      #: -> [Integer, Integer]
      def range = raise NotImplementedError, "Abstract method called"
    end

    class Insert < Edit
      #: Integer
      attr_reader :position

      #: String
      attr_reader :text

      #: (Integer, String) -> void
      def initialize(position, text)
        super()

        @position = position
        @text = text
      end

      # @override
      #: (Array[Integer]) -> void
      def apply(bytes)
        raise PositionError, "Position is out of bounds" if position < 0 || position > bytes.size

        bytes #: untyped
          .insert(position, *text.bytes)
      end

      # @override
      #: -> [Integer, Integer]
      def range
        [position, position]
      end

      # @override
      #: -> String
      def to_s
        "Insert `#{text}` at #{position}"
      end
    end

    class Replace < Edit
      #: Integer
      attr_reader :from, :to

      #: String
      attr_reader :text

      #: (Integer, Integer, String) -> void
      def initialize(from, to, text)
        super()

        @from = from
        @to = to
        @text = text
      end

      # @override
      #: (Array[Integer]) -> void
      def apply(bytes)
        raise PositionError,
          "Position is out of bounds" if from < 0 || to < 0 || from > bytes.size || to > bytes.size || from > to

        bytes[from..to] = *text.bytes
      end

      # @override
      #: -> [Integer, Integer]
      def range
        [from, to]
      end

      # @override
      #: -> String
      def to_s
        "Replace #{from}-#{to} with `#{text}`"
      end
    end

    class Delete < Edit
      #: Integer
      attr_reader :from, :to

      #: (Integer, Integer) -> void
      def initialize(from, to)
        super()

        @from = from
        @to = to
      end

      # @override
      #: (Array[untyped]) -> void
      def apply(bytes)
        raise PositionError,
          "Position is out of bounds" if from < 0 || to < 0 || from > bytes.size || to > bytes.size || from > to

        bytes[from..to] = "".bytes
      end

      # @override
      #: -> [Integer, Integer]
      def range
        [from, to]
      end

      # @override
      #: -> String
      def to_s
        "Delete #{from}-#{to}"
      end
    end

    class Rewriter
      #: -> void
      def initialize
        @edits = [] #: Array[Edit]
      end

      #: (Edit) -> void
      def <<(other)
        @edits << other
      end

      #: (Array[Integer]) -> void
      def rewrite!(bytes)
        # To avoid remapping positions after each edit,
        # we sort the changes by position and apply them in reverse order.
        # When ranges are equal, preserve the original order
        @edits.each_with_index.sort_by do |(edit, idx)|
          [edit.range, idx]
        end.reverse_each do |(edit, _)|
          edit.apply(bytes)
        end
      end
    end
  end
end
