# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class SorbetTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_ignore_sorbet_type_members
          @project.write!("foo.rb", <<~RB)
            Elem1 = type_member
            Elem2 = type_template
            Elem3 = type_member { {fixed: String} }
            Const = 42
          RB

          index = index_with_plugins
          assert_ignored(index, "Elem1")
          assert_ignored(index, "Elem2")
          assert_ignored(index, "Elem3")
          refute_ignored(index, "Const")
        end

        def test_ignore_sorbet_enum_constants
          @project.write!("foo.rb", <<~RB)
            enums do
              DEAD1 = new
            end

            class BadEnum < T::Enum
              class BadEnum
                enums do
                  DEAD2 = new
                end
              end
            end

            class Foo
              enums do
                DEAD3 = new
              end
            end

            class SomeEnum < T::Enum
              enums do
                IGNORED1 = new
                IGNORED2 = new
              end
            end

            module Foo
              class OtherEnum < ::T::Enum
                enums do
                  IGNORED3 = new
                  IGNORED4 = new
                end
              end
            end

            class BadEnum < T::Enum
              something do
                IGNORED5 = new
              end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "IGNORED1")
          assert_ignored(index, "IGNORED2")
          assert_ignored(index, "IGNORED3")
          assert_ignored(index, "IGNORED4")
          assert_ignored(index, "IGNORED5")
          refute_ignored(index, "DEAD1")
          refute_ignored(index, "DEAD2")
          refute_ignored(index, "DEAD3")
        end

        def test_ignore_sorbet_overrides
          @project.write!("foo.rb", <<~RB)
            def dead1; end

            sig { void }
            def dead2; end

            sig { override.void }
            def ignored1; end

            sig { overridable.void }
            def ignored2; end

            def dead3; end
          RB

          index = index_with_plugins
          assert_ignored(index, "ignored1")
          assert_ignored(index, "ignored2")
          refute_ignored(index, "dead1")
          refute_ignored(index, "dead2")
          refute_ignored(index, "dead3")
        end

        def test_ignore_sorbet_override_comments
          @project.write!("foo.rb", <<~RB)
            def dead1; end

            sig { void }
            def dead2; end

            # @override
            def ignored1; end

            # @overridable
            def ignored2; end

            def dead3; end
          RB

          index = index_with_plugins
          assert_ignored(index, "ignored1")
          assert_ignored(index, "ignored2")
          refute_ignored(index, "dead1")
          refute_ignored(index, "dead2")
          refute_ignored(index, "dead3")
        end

        private

        #: -> Deadcode::Index
        def index_with_plugins
          deadcode_index(plugin_classes: [Plugins::Sorbet])
        end
      end
    end
  end
end
