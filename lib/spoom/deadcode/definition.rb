# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    # A definition is a class, module, method, constant, etc. being defined in the code
    class Definition < T::Struct
      extend T::Sig

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

      const :kind, Kind
      const :name, String
      const :full_name, String
      const :location, Location
      const :status, Status, default: Status::DEAD

      # Kind

      sig { returns(T::Boolean) }
      def attr_reader?
        kind == Kind::AttrReader
      end

      sig { returns(T::Boolean) }
      def attr_writer?
        kind == Kind::AttrWriter
      end

      sig { returns(T::Boolean) }
      def class?
        kind == Kind::Class
      end

      sig { returns(T::Boolean) }
      def constant?
        kind == Kind::Constant
      end

      sig { returns(T::Boolean) }
      def method?
        kind == Kind::Method
      end

      sig { returns(T::Boolean) }
      def module?
        kind == Kind::Module
      end

      # Status

      sig { returns(T::Boolean) }
      def alive?
        status == Status::ALIVE
      end

      sig { void }
      def alive!
        @status = Status::ALIVE
      end

      sig { returns(T::Boolean) }
      def dead?
        status == Status::DEAD
      end

      sig { returns(T::Boolean) }
      def ignored?
        status == Status::IGNORED
      end

      sig { void }
      def ignored!
        @status = Status::IGNORED
      end

      # Utils

      sig { params(args: T.untyped).returns(String) }
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
