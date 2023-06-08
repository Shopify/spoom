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

        sig { returns(Deadcode::Index) }
        def deadcode_index
          files = project.collect_files(
            allow_extensions: [".rb", ".erb", ".rake", ".rakefile", ".gemspec"],
            allow_mime_types: ["text/x-ruby", "text/x-ruby-script"],
          )

          index = Deadcode::Index.new

          files.each do |file|
            content = project.read(file)
            Spoom::Deadcode.index_ruby(index, content, file: file)
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
