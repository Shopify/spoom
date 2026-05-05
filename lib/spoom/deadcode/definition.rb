# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    # A definition is a class, module, method, constant, etc. being defined in the code
    class Definition
      class Kind < T::Enum
        enums do
          AttrReader = new("attr_reader")
          AttrWriter = new("attr_writer")
          Class = new("class")
          Constant = new("constant")
          Method = new("method")
          Module = new("module")
        end
      end

      class Status < T::Enum
        enums do
          # A definition is marked as `ALIVE` if it has at least one reference with the same name
          ALIVE = new
          # A definition is marked as `DEAD` if it has no reference with the same name
          DEAD = new
          # A definition can be marked as `IGNORED` if it is not relevant for the analysis
          IGNORED = new
        end
      end

      #: Kind
      attr_reader :kind

      #: String
      attr_reader :name

      #: String
      attr_reader :full_name

      #: Location
      attr_reader :location

      #: Status
      attr_reader :status

      #: (kind: Kind, name: String, full_name: String, location: Location, ?status: Status) -> void
      def initialize(kind:, name:, full_name:, location:, status: Status::DEAD)
        @kind = kind
        @name = name
        @full_name = full_name
        @location = location
        @status = status
      end

      # Kind

      #: -> bool
      def attr_reader?
        kind == Kind::AttrReader
      end

      #: -> bool
      def attr_writer?
        kind == Kind::AttrWriter
      end

      #: -> bool
      def class?
        kind == Kind::Class
      end

      #: -> bool
      def constant?
        kind == Kind::Constant
      end

      #: -> bool
      def method?
        kind == Kind::Method
      end

      #: -> bool
      def module?
        kind == Kind::Module
      end

      # Status

      #: -> bool
      def alive?
        status == Status::ALIVE
      end

      #: -> void
      def alive!
        @status = Status::ALIVE
      end

      #: -> bool
      def dead?
        status == Status::DEAD
      end

      #: -> bool
      def ignored?
        status == Status::IGNORED
      end

      #: -> void
      def ignored!
        @status = Status::IGNORED
      end

      # Utils

      #: (*untyped args) -> String
      def to_json(*args)
        {
          kind: kind,
          name: name,
          location: location.to_s,
        }.to_json
      end
    end
  end
end
