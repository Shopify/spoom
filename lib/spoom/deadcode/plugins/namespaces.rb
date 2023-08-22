# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Namespaces < Base
        extend T::Sig

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_class(indexer, definition)
          definition.ignored! if used_as_namespace?(indexer)
        end

        sig { override.params(indexer: Indexer, definition: Definition).void }
        def on_define_module(indexer, definition)
          definition.ignored! if used_as_namespace?(indexer)
        end

        private

        sig { params(indexer: Indexer).returns(T::Boolean) }
        def used_as_namespace?(indexer)
          node = indexer.current_node
          return false unless node.is_a?(SyntaxTree::ClassDeclaration) || node.is_a?(SyntaxTree::ModuleDeclaration)

          node.bodystmt.statements.body.any? do |stmt|
            !stmt.is_a?(SyntaxTree::VoidStmt)
          end
        end
      end
    end
  end
end
