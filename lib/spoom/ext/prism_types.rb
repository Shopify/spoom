# typed: strict
# frozen_string_literal: true

module Spoom
  module PrismTypes
    # Ideally this would just be in a shim in `sorbet/rbi/shims/prism.rbi`, but that causes
    # `bundle exec tapioca gem spoom` to fail. It Spoom's translator to rewrite the RBS signature comments into Sigs,
    # which try to access the `Prism::AnyScopeNode` constant.
    # Because shims aren't executed, no such constant exists at runtime, and the Sig raises a NameError.
    #
    # So instead, we define it here, where the translator can reify it into a real Sorbet `T.type_alias` at runtime.
    #: type anyScopeNode = ::Prism::ClassNode | ::Prism::ModuleNode | ::Prism::SingletonClassNode
  end
end
