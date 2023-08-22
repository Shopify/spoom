# typed: strict
# frozen_string_literal: true

require "set"

module Spoom
  module Deadcode
    module Plugins
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        class << self
          extend T::Sig

          # Plugins DSL

          # Mark classes matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_class_names(
          #     "Foo",
          #     "Bar",
          #     /Baz.*/,
          #   )
          # end
          # ~~~
          sig { params(names: T.any(String, Regexp)).void }
          def ignore_classes_named(*names)
            save_names_and_patterns(names, :@ignored_class_names, :@ignored_class_patterns)
          end

          # Mark classes directly subclassing a class matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_classes_inheriting_from(
          #     "Foo",
          #     "Bar",
          #     /Baz.*/,
          #   )
          # end
          # ~~~
          sig { params(names: T.any(String, Regexp)).void }
          def ignore_classes_inheriting_from(*names)
            save_names_and_patterns(names, :@ignored_subclasses_of_names, :@ignored_subclasses_of_patterns)
          end

          # Mark constants matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_class_names(
          #     "FOO",
          #     "BAR",
          #     /BAZ.*/,
          #   )
          # end
          # ~~~
          sig { params(names: T.any(String, Regexp)).void }
          def ignore_constants_named(*names)
            save_names_and_patterns(names, :@ignored_constant_names, :@ignored_constant_patterns)
          end

          # Mark methods matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_method_names(
          #     "foo",
          #     "bar",
          #     /baz.*/,
          #   )
          # end
          # ~~~
          sig { params(names: T.any(String, Regexp)).void }
          def ignore_methods_named(*names)
            save_names_and_patterns(names, :@ignored_method_names, :@ignored_method_patterns)
          end

          # Mark modules matching `names` as ignored.
          #
          # Names can be either strings or regexps:
          #
          # ~~~rb
          # class MyPlugin < Spoom::Deadcode::Plugins::Base
          #   ignore_class_names(
          #     "Foo",
          #     "Bar",
          #     /Baz.*/,
          #   )
          # end
          # ~~~
          sig { params(names: T.any(String, Regexp)).void }
          def ignore_modules_named(*names)
            save_names_and_patterns(names, :@ignored_module_names, :@ignored_module_patterns)
          end

          private

          sig { params(names: T::Array[T.any(String, Regexp)], names_variable: Symbol, patterns_variable: Symbol).void }
          def save_names_and_patterns(names, names_variable, patterns_variable)
            ignored_names = instance_variable_set(names_variable, Set.new)
            ignored_patterns = instance_variable_set(patterns_variable, [])

            names.each do |name|
              case name
              when String
                ignored_names << name.delete_prefix("::")
              when Regexp
                ignored_patterns << name
              end
            end
          end
        end

        # Indexing event methods

        # Called when an accessor is defined.
        #
        # Will be called when the indexer processes a `attr_reader`, `attr_writer` or `attr_accessor` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_accessor(indexer, definition)
        #     definition.ignored! if definition.name == "foo"
        #   end
        # end
        # ~~~
        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_accessor(indexer, definition)
          # no-op
        end

        # Do not override this method, use `on_define_accessor` instead.
        sig { params(indexer: Indexer, definition: Definition).void }
        def internal_on_define_accessor(indexer, definition)
          on_define_accessor(indexer, definition)
        end

        # Called when a class is defined.
        #
        # Will be called when the indexer processes a `class` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_class(indexer, definition)
        #     definition.ignored! if definition.name == "Foo"
        #   end
        # end
        # ~~~
        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_class(indexer, definition)
          # no-op
        end

        # Do not override this method, use `on_define_class` instead.
        sig { params(indexer: Indexer, definition: Definition).void }
        def internal_on_define_class(indexer, definition)
          if ignored_class_name?(definition.name)
            definition.ignored!
          elsif ignored_subclass?(indexer.nesting_class_superclass_name)
            definition.ignored!
          end

          on_define_class(indexer, definition)
        end

        # Called when a constant is defined.
        #
        # Will be called when the indexer processes a `CONST =` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_constant(indexer, definition)
        #     definition.ignored! if definition.name == "FOO"
        #   end
        # end
        # ~~~
        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_constant(indexer, definition)
          # no-op
        end

        # Do not override this method, use `on_define_constant` instead.
        sig { params(indexer: Indexer, definition: Definition).void }
        def internal_on_define_constant(indexer, definition)
          definition.ignored! if ignored_constant_name?(definition.name)

          on_define_constant(indexer, definition)
        end

        # Called when a method is defined.
        #
        # Will be called when the indexer processes a `def` or `defs` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_method(indexer, definition)
        #     super # So the `ignore_method_names` DSL is still applied
        #
        #     definition.ignored! if definition.name == "foo"
        #   end
        # end
        # ~~~
        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_method(indexer, definition)
          # no-op
        end

        # Do not override this method, use `on_define_method` instead.
        sig { params(indexer: Indexer, definition: Definition).void }
        def internal_on_define_method(indexer, definition)
          definition.ignored! if ignored_method_name?(definition.name)

          on_define_method(indexer, definition)
        end

        # Called when a module is defined.
        #
        # Will be called when the indexer processes a `module` node.
        # Note that when this method is called, the definition for the node has already been added to the index.
        # It is still possible to ignore it from the plugin:
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_define_module(indexer, definition)
        #     definition.ignored! if definition.name == "Foo"
        #   end
        # end
        # ~~~
        sig { params(indexer: Indexer, definition: Definition).void }
        def on_define_module(indexer, definition)
          # no-op
        end

        # Do not override this method, use `on_define_module` instead.
        sig { params(indexer: Indexer, definition: Definition).void }
        def internal_on_define_module(indexer, definition)
          definition.ignored! if ignored_module_name?(definition.name)

          on_define_module(indexer, definition)
        end

        # Called when a send is being processed
        #
        # ~~~rb
        # class MyPlugin < Spoom::Deadcode::Plugins::Base
        #   def on_send(indexer, send)
        #     return unless send.name == "dsl_method"
        #     return if send.args.empty?
        #
        #     method_name = indexer.node_string(send.args.first).delete_prefix(":")
        #     indexer.reference_method(method_name, send.node)
        #   end
        # end
        # ~~~
        sig { params(indexer: Indexer, send: Send).void }
        def on_send(indexer, send)
          # no-op
        end

        # Do not override this method, use `on_send` instead.
        sig { params(indexer: Indexer, send: Send).void }
        def internal_on_send(indexer, send)
          on_send(indexer, send)
        end

        private

        # DSL support

        sig { params(name: T.nilable(String)).returns(T::Boolean) }
        def ignored_class_name?(name)
          return false unless name

          ignored_name?(name, :@ignored_class_names, :@ignored_class_patterns)
        end

        sig { params(superclass_name: T.nilable(String)).returns(T::Boolean) }
        def ignored_subclass?(superclass_name)
          return false unless superclass_name

          ignored_name?(superclass_name, :@ignored_subclasses_of_names, :@ignored_subclasses_of_patterns)
        end

        sig { params(name: String).returns(T::Boolean) }
        def ignored_constant_name?(name)
          ignored_name?(name, :@ignored_constant_names, :@ignored_constant_patterns)
        end

        sig { params(name: String).returns(T::Boolean) }
        def ignored_method_name?(name)
          ignored_name?(name, :@ignored_method_names, :@ignored_method_patterns)
        end

        sig { params(name: String).returns(T::Boolean) }
        def ignored_module_name?(name)
          ignored_name?(name, :@ignored_module_names, :@ignored_module_patterns)
        end

        sig { params(name: String, names_variable: Symbol, patterns_variable: Symbol).returns(T::Boolean) }
        def ignored_name?(name, names_variable, patterns_variable)
          names(names_variable).include?(name) || patterns(patterns_variable).any? { |pattern| pattern.match?(name) }
        end

        sig { params(const: Symbol).returns(T::Set[String]) }
        def names(const)
          self.class.instance_variable_get(const) || Set.new
        end

        sig { params(const: Symbol).returns(T::Array[Regexp]) }
        def patterns(const)
          self.class.instance_variable_get(const) || []
        end

        # Plugin utils

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
