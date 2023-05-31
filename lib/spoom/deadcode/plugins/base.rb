# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        class << self
          extend T::Sig

          sig { params(names: T.any(String, Regexp)).void }
          def ignore_class_names(*names)
            ignored_class_names = instance_variable_set(:@ignored_class_names, Set.new)
            ignored_class_patterns = instance_variable_set(:@ignored_class_patterns, [])

            names.each do |name|
              case name
              when String
                ignored_class_names << name
              when Regexp
                ignored_class_patterns << name
              end
            end
          end

          sig do
            params(block: T.proc.bind(T.attached_class).params(indexer: Indexer, definition: Definition).void).void
          end
          def ignore_classes_if(&block)
            instance_variable_set(:@ignore_classes_if, block)
          end

          sig { params(names: T.any(String, Regexp)).void }
          def ignore_subclasses_of(*names)
            ignored_subclasses_of_names = instance_variable_set(:@ignored_subclasses_of_names, Set.new)
            ignored_subclasses_of_patterns = instance_variable_set(:@ignored_subclasses_of_patterns, [])

            names.each do |name|
              case name
              when String
                ignored_subclasses_of_names << name
              when Regexp
                ignored_subclasses_of_patterns << name
              end
            end
          end

          sig { params(names: T.any(String, Regexp)).void }
          def ignore_constant_names(*names)
            ignored_constant_names = instance_variable_set(:@ignored_constant_names, Set.new)
            ignored_constant_patterns = instance_variable_set(:@ignored_constant_patterns, [])

            names.each do |name|
              case name
              when String
                ignored_constant_names << name
              when Regexp
                ignored_constant_patterns << name
              end
            end
          end

          sig do
            params(block: T.proc.bind(T.attached_class).params(indexer: Indexer, definition: Definition).void).void
          end
          def ignore_constants_if(&block)
            instance_variable_set(:@ignore_constants_if, block)
          end

          sig { params(names: T.any(String, Regexp)).void }
          def ignore_method_names(*names)
            ignored_method_names = instance_variable_set(:@ignored_method_names, Set.new)
            ignored_method_patterns = instance_variable_set(:@ignored_method_patterns, [])

            names.each do |name|
              case name
              when String
                ignored_method_names << name
              when Regexp
                ignored_method_patterns << name
              end
            end
          end

          sig do
            params(block: T.proc.bind(T.attached_class).params(indexer: Indexer, definition: Definition).void).void
          end
          def ignore_methods_if(&block)
            instance_variable_set(:@ignore_methods_if, block)
          end

          sig { params(names: T.any(String, Regexp)).void }
          def ignore_module_names(*names)
            ignored_module_names = instance_variable_set(:@ignored_module_names, Set.new)
            ignored_module_patterns = instance_variable_set(:@ignored_module_patterns, [])

            names.each do |name|
              case name
              when String
                ignored_module_names << name
              when Regexp
                ignored_module_patterns << name
              end
            end
          end

          sig do
            params(block: T.proc.bind(T.attached_class).params(indexer: Indexer, definition: Definition).void).void
          end
          def ignore_modules_if(&block)
            instance_variable_set(:@ignore_modules_if, block)
          end

          sig { params(names: String).void }
          def reference_send_symbols_as_methods(*names)
            reference_send_symbols_as_methods = instance_variable_set(:@reference_send_symbols_as_methods, Set.new)
            names.each { |name| reference_send_symbols_as_methods << name }
          end
        end

        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_accessor(indexer, definition)
          # no-op
        end

        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_class(indexer, definition)
          block = self.class.instance_variable_get(:@ignore_classes_if)
          if block && instance_exec(indexer, definition, &block)
            definition.ignored!
            return
          end

          if ignored_class_name?(definition.name)
            definition.ignored!
            return
          end

          if ignored_subclass?(indexer.nesting_class_superclass_name)
            definition.ignored!
          end
        end

        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_constant(indexer, definition)
          block = self.class.instance_variable_get(:@ignore_constants_if)
          if block && instance_exec(indexer, definition, &block)
            definition.ignored!
            return
          end

          if ignored_constant_name?(definition.name)
            definition.ignored!
          end
        end

        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_method(indexer, definition)
          block = self.class.instance_variable_get(:@ignore_methods_if)
          if block && instance_exec(indexer, definition, &block)
            definition.ignored!
            return
          end

          if ignored_method_name?(definition.name)
            definition.ignored!
          end
        end

        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_module(indexer, definition)
          block = self.class.instance_variable_get(:@ignore_modules_if)
          if block && instance_exec(indexer, definition, &block)
            definition.ignored!
            return
          end

          if ignored_module_name?(definition.name)
            definition.ignored!
          end
        end

        sig { params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          return unless send.recv.nil?

          names = names(:@reference_send_symbols_as_methods)
          return unless names.include?(send.name)

          reference_send_symbols_as_methods(indexer, send)
        end

        private

        sig { params(name: T.nilable(String)).returns(T::Boolean) }
        def ignored_class_name?(name)
          return false unless name
          return true if names(:@ignored_class_names).include?(name)
          return true if patterns(:@ignored_class_patterns).any? { |p| p.match?(name) }

          false
        end

        sig { params(superclass_name: T.nilable(String)).returns(T::Boolean) }
        def ignored_subclass?(superclass_name)
          return false unless superclass_name
          return true if names(:@ignored_subclasses_of_names).include?(superclass_name)
          return true if patterns(:@ignored_subclasses_of_patterns).any? { |p| p.match?(superclass_name) }

          false
        end

        sig { params(name: String).returns(T::Boolean) }
        def ignored_constant_name?(name)
          names(:@ignored_constant_names).include?(name)
        end

        sig { params(name: String).returns(T::Boolean) }
        def ignored_method_name?(name)
          names(:@ignored_method_names).include?(name)
        end

        sig { params(name: String).returns(T::Boolean) }
        def ignored_module_name?(name)
          names(:@ignored_module_names).include?(name)
        end

        sig { params(const: Symbol).returns(T::Set[String]) }
        def names(const)
          self.class.instance_variable_get(const) || Set.new
        end

        sig { params(const: Symbol).returns(T::Array[Regexp]) }
        def patterns(const)
          self.class.instance_variable_get(const) || []
        end

        sig { params(indexer: Indexer, send: Send).void }
        def reference_send_symbols_as_methods(indexer, send)
          send.args.each do |arg|
            next unless arg.is_a?(SyntaxTree::SymbolLiteral)

            indexer.reference_method(indexer.node_string(arg.value), send.node)
          end
        end

        sig { params(indexer: Indexer, send: Send).void }
        def reference_send_first_symbol_as_method(indexer, send)
          first_arg = send.args.first
          return unless first_arg.is_a?(SyntaxTree::SymbolLiteral)

          name = indexer.node_string(first_arg.value)
          indexer.reference_method(name, send.node)
        end

        sig { params(indexer: Indexer, send: Send).void }
        def reference_send_first_symbol_as_constant(indexer, send)
          first_arg = send.args.first
          return unless first_arg.is_a?(SyntaxTree::SymbolLiteral)

          name = indexer.node_string(first_arg.value)
          indexer.reference_constant(name, send.node)
        end

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
end
