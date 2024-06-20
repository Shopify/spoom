# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    # A SendListener is used to populate the references found by a ReferencesVisitor
    #
    # Each listener knows how to process a specific DSL (like Rails, GraphQL, etc) and how to create references for it.
    class SendListener
      extend T::Sig
      extend T::Helpers

      abstract!

      # Called when a send is being processed
      #
      # ~~~rb
      # class MyListener < Spoom::Model::SendListener
      #   def on_send(visitor, send)
      #     return unless send.name == "dsl_method"
      #     return if send.args.empty?
      #
      #     method_name = send.args.first.slice.delete_prefix(":")
      #     visitor.reference_method(method_name, send.node)
      #   end
      # end
      # ~~~
      sig { abstract.params(visitor: ReferencesVisitor, send: Send).void }
      def on_send(visitor, send); end

      private

      sig { params(name: String).returns(String) }
      def camelize(name)
        name = T.must(name.split("::").last)
        name = T.must(name.split("/").last)
        name = name.gsub(/[^a-zA-Z0-9_]/, "")
        name = name.sub(/^[a-z\d]*/, &:capitalize)
        name = name.gsub(%r{(?:_|(/))([a-z\d]*)}) do
          s1 = Regexp.last_match(1)
          s2 = Regexp.last_match(2)
          "#{s1}#{s2&.capitalize}"
        end
        name
      end
    end
  end
end

require_relative "send_listeners/action_mailer"
require_relative "send_listeners/actionpack"
require_relative "send_listeners/active_model"
require_relative "send_listeners/active_record"
require_relative "send_listeners/active_support"
require_relative "send_listeners/graphql"
require_relative "send_listeners/ruby"
