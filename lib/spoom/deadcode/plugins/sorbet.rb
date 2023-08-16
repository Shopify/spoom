# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Sorbet < Base
        extend T::Sig

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_constant(indexer, definition)
          definition.ignored! if sorbet_type_member?(indexer, definition) || sorbet_enum_constant?(indexer, definition)
        end

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_method(indexer, definition)
          definition.ignored! if indexer.last_sig =~ /(override|overridable)/
        end

        private

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def sorbet_type_member?(indexer, definition)
          assign = indexer.nesting_node(SyntaxTree::Assign)
          return false unless assign

          value = assign.value

          case value
          when SyntaxTree::MethodAddBlock
            indexer.node_string(value.call).match?(/^(type_member|type_template)/)
          when SyntaxTree::VCall
            indexer.node_string(value.value).match?(/^(type_member|type_template)/)
          else
            false
          end
        end

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def sorbet_enum_constant?(indexer, definition)
          /^(::)?T::Enum$/.match?(indexer.nesting_class_superclass_name) && indexer.nesting_block_call_name == "enums"
        end
      end
    end
  end
end
