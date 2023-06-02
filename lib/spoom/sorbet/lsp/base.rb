# typed: strict
# frozen_string_literal: true

module Spoom
  module LSP
    # Base messaging
    # We don't use T::Struct for those so we can subclass them

    # A general message as defined by JSON-RPC.
    #
    # The language server protocol always uses `"2.0"` as the `jsonrpc` version.
    class Message
      extend T::Sig

      sig { void }
      def initialize
        @jsonrpc = T.let("2.0", String)
      end

      sig { returns(T::Hash[T.untyped, T.untyped]) }
      def as_json
        instance_variables.each_with_object({}) do |var, obj|
          val = instance_variable_get(var)
          obj[var.to_s.delete("@")] = val if val
        end
      end

      sig { params(args: T.untyped).returns(String) }
      def to_json(*args)
        T.unsafe(as_json).to_json(*args)
      end
    end

    # A request message to describe a request between the client and the server.
    #
    # Every processed request must send a response back to the sender of the request.
    class Request < Message
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :id

      sig { returns(T::Hash[T.untyped, T.untyped]) }
      attr_reader :params

      sig { params(id: Integer, method: String, params: T::Hash[T.untyped, T.untyped]).void }
      def initialize(id, method, params)
        super()
        @id = id
        @method = method
        @params = params
      end
    end

    # A notification message.
    #
    # A processed notification message must not send a response back. They work like events.
    class Notification < Message
      extend T::Sig

      sig { returns(String) }
      attr_reader :method

      sig { returns(T::Hash[T.untyped, T.untyped]) }
      attr_reader :params

      sig { params(method: String, params: T::Hash[T.untyped, T.untyped]).void }
      def initialize(method, params)
        super()
        @method = method
        @params = params
      end
    end
  end
end
