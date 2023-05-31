# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Sorbet < Base
        extend T::Sig

        TYPE_MEMBER_RE = T.let(/^(type_member|type_template)/.freeze, Regexp)
        T_ENUM_RE = T.let(/^(::)?T::Enum$/.freeze, Regexp)

        ignore_constants_if do |indexer, definition|
          sorbet_type_member?(indexer, definition) || sorbet_enum_constant?(indexer, definition)
        end

        ignore_methods_if { |indexer, _definition| indexer.last_sig&.match?(/(override|overridable)\./) }

        private

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def sorbet_type_member?(indexer, definition)
          assign = indexer.nesting_node(SyntaxTree::Assign)
          return false unless assign.is_a?(SyntaxTree::Assign)

          value = assign.value
          message = case value
          when SyntaxTree::MethodAddBlock
            indexer.node_string(value.call)
          when SyntaxTree::VCall
            indexer.node_string(value.value)
          end

          TYPE_MEMBER_RE.match?(message)
        end

        sig { params(indexer: Indexer, definition: Definition).returns(T::Boolean) }
        def sorbet_enum_constant?(indexer, definition)
          T_ENUM_RE.match?(indexer.nesting_class_superclass_name) && indexer.nesting_block_call_name == "enums"
        end
      end
    end
  end
end
