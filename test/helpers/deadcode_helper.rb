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

        sig { params(plugins: T::Array[Deadcode::Plugins::Base]).returns(Deadcode::Index) }
        def deadcode_index(plugins: [])
          files = project.collect_files(
            allow_extensions: [".rb", ".erb", ".rake", ".rakefile", ".gemspec"],
            allow_mime_types: ["text/x-ruby", "text/x-ruby-script"],
          )

          index = Deadcode::Index.new

          files.each do |file|
            content = project.read(file)
            if file.end_with?(".erb")
              Spoom::Deadcode.index_erb(index, content, file: file, plugins: plugins)
            else
              Spoom::Deadcode.index_ruby(index, content, file: file, plugins: plugins)
            end
          end

          index.finalize!
          index
        end

        # Assertions

        sig { params(index: Deadcode::Index, name: String).void }
        def assert_alive(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.all?(&:alive?), "Expected all definitions for `#{name}` to be alive")
        end

        sig { params(index: Deadcode::Index, name: String).void }
        def assert_dead(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.all?(&:dead?), "Expected all definitions for `#{name}` to be dead")
        end

        sig { params(index: Deadcode::Index, name: String).void }
        def assert_ignored(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.all?(&:ignored?), "Expected all definitions for `#{name}` to be ignored")
        end

        sig { params(index: Deadcode::Index, name: String).void }
        def assert_typed(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.all?(&:typed?), "Expected all definitions for `#{name}` to be typed")
        end

        sig { params(index: Deadcode::Index, name: String).void }
        def assert_untyped(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.none?(&:typed?), "Expected all definitions for `#{name}` to be untyped")
        end

        sig { params(index: Deadcode::Index, name: String).void }
        def refute_ignored(index, name)
          defs = definitions_for_name(index, name)
          assert(defs.none?(&:ignored?), "Expected all definitions for `#{name}` to not be ignored")
        end

        private

        sig { params(index: Deadcode::Index, name: String).returns(T::Array[Deadcode::Definition]) }
        def definitions_for_name(index, name)
          defs = index.definitions_for_name(name)
          refute_empty(defs, "No indexed definition found for `#{name}`")
          defs
        end
      end
    end
  end
end
