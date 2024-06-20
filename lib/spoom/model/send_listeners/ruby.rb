# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class SendListener
      class Ruby < SendListener
        sig { override.params(visitor: Model::ReferencesVisitor, send: Model::Send).void }
        def on_send(visitor, send)
          case send.name
          when "const_defined?", "const_get", "const_source_location"
            arg = T.must(send.args.first)
            case arg
            when Prism::SymbolNode
              visitor.reference_constant(arg.unescaped, arg)
            when Prism::StringNode
              arg.unescaped.split("::").each do |name|
                visitor.reference_constant(name, arg) unless name.empty?
              end
            end
          when "send", "__send__", "try"
            arg = send.args.first
            visitor.reference_method(arg.unescaped, arg) if arg.is_a?(Prism::SymbolNode)
          when "alias_method"
            last_arg = send.args.last

            if last_arg.is_a?(Prism::SymbolNode) || last_arg.is_a?(Prism::StringNode)
              visitor.reference_method(last_arg.unescaped, last_arg)
            end
          end
        end
      end
    end
  end
end
