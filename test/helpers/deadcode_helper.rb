# typed: strict
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Test
    module Helpers
      module DeadcodeHelper
        extend T::Sig
        extend T::Helpers

        requires_ancestor { TestWithProject }

        # Indexing

        #: (?plugin_classes: Array[singleton(Deadcode::Plugins::Base)]) -> Deadcode::Index
        def deadcode_index(plugin_classes: [])
          files = project.collect_files(
            allow_extensions: [".rb", ".erb", ".rake", ".rakefile", ".gemspec"],
            allow_mime_types: ["text/x-ruby", "text/x-ruby-script"],
          )

          model = Model.new
          index = Deadcode::Index.new(model)
          plugins = plugin_classes.map { |plugin| plugin.new(index) }

          files.each do |file|
            content = project.read(file)
            if file.end_with?(".erb")
              index.index_erb(content, file: file, plugins: plugins)
            else
              index.index_ruby(content, file: file, plugins: plugins)
            end
          end

          model.finalize!
          index.apply_plugins!(plugins)
          index.finalize!
          index
        end

        # Assertions

        #: (Deadcode::Index index, String name) -> void
        def assert_alive(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.all?(&:alive?), "Expected all definitions for `#{name}` to be alive")
        end

        #: (Deadcode::Index index, String name) -> void
        def assert_dead(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.all?(&:dead?), "Expected all definitions for `#{name}` to be dead")
        end

        #: (Deadcode::Index index, String name) -> void
        def assert_ignored(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.all?(&:ignored?), "Expected all definitions for `#{name}` to be ignored")
        end

        #: (Deadcode::Index index, String name) -> void
        def refute_ignored(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.none?(&:ignored?), "Expected all definitions for `#{name}` to not be ignored")
        end

        private

        #: (Deadcode::Index index, String name) -> Array[Deadcode::Definition]
        def definitions_for_name(index, name)
          defs = index.definitions_for_name(name)
          refute_empty(defs, "No indexed definition found for `#{name}`")
          defs
        end
      end
    end
  end
end
