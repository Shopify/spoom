# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    class RemoverTest < Spoom::TestWithProject
      include Test::Helpers::DeadcodeHelper

      def test_deadcode_remover_raises_if_file_does_not_exist
        context = Context.mktmp!
        remover = Remover.new(context)

        assert_raises(Remover::Error) do
          remover.remove_location(Definition::Kind::Class, Location.from_string("foo.rb:1:1-1:1"))
        end

        context.destroy!
      end

      def test_deadcode_remover_raises_if_node_cant_be_found
        context = Context.mktmp!
        context.write!("foo.rb", "")
        remover = Remover.new(context)

        assert_raises(Remover::Error) do
          remover.remove_location(Definition::Kind::Class, Location.from_string("foo.rb:1:1-1:1"))
        end

        context.destroy!
      end

      def test_deadcode_remover_raises_if_node_doesnt_match_kind
        context = Context.mktmp!
        context.write!("foo.rb", <<~RB)
          class Foo; end
          class Bar; end
        RB

        remover = Remover.new(context)

        assert_raises(Remover::Error) do
          remover.remove_location(Definition::Kind::Module, Location.from_string("foo.rb:1:0-1:14"))
        end

        context.destroy!
      end

      def test_deadcode_remover_removes_first_const_of_root
        res = remove(<<~RB, "FOO")
          FOO = 42
          BAR = 42
          BAZ = 42
        RB

        assert_equal(<<~RB, res)
          BAR = 42
          BAZ = 42
        RB
      end

      def test_deadcode_remover_removes_middle_const_of_root
        res = remove(<<~RB, "BAR")
          FOO = 42
          BAR = 42
          BAZ = 42
        RB

        assert_equal(<<~RB, res)
          FOO = 42
          BAZ = 42
        RB
      end

      def test_deadcode_remover_removes_last_const_of_root
        res = remove(<<~RB, "BAZ")
          FOO = 42
          BAR = 42
          BAZ = 42
        RB

        assert_equal(<<~RB, res)
          FOO = 42
          BAR = 42
        RB
      end

      def test_deadcode_remover_removes_const_path
        res = remove(<<~RB, "BAZ")
          ::FOO::BAR = 42
          ::FOO::BAZ = 42
        RB

        assert_equal(<<~RB, res)
          ::FOO::BAR = 42
        RB
      end

      def test_deadcode_remover_removes_first_nested_const
        res = remove(<<~RB, "FOO")
          class Foo
            FOO = 42
            BAR = 42
            BAZ = 42
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            BAR = 42
            BAZ = 42
          end
        RB
      end

      def test_deadcode_remover_removes_middle_nested_const
        res = remove(<<~RB, "BAR")
          class Foo
            FOO = 42
            BAR = 42
            BAZ = 42
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            FOO = 42
            BAZ = 42
          end
        RB
      end

      def test_deadcode_remover_removes_middle_nested_const_with_blank_line_after
        res = remove(<<~RB, "BAR")
          class Foo
            FOO = 42
            BAR = 42

            # Some comment
            BAZ = 42
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            FOO = 42

            # Some comment
            BAZ = 42
          end
        RB
      end

      def test_deadcode_remover_removes_last_nested_const
        res = remove(<<~RB, "BAZ")
          class Foo
            FOO = 42
            BAR = 42
            BAZ = 42
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            FOO = 42
            BAR = 42
          end
        RB
      end

      def test_deadcode_remover_removes_multiline_const
        res = remove(<<~RB, "BAR")
          class Foo
            FOO = 42

            BAR = <<~FOO
              Some text
            FOO

            BAZ = 42
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            FOO = 42

            BAZ = 42
          end
        RB
      end

      def test_deadcode_remover_removes_first_const_from_massign
        res = remove(<<~RB, "FOO")
          FOO, BAR, BAZ = 42
        RB

        assert_equal(<<~RB, res)
          BAR, BAZ = 42
        RB
      end

      def test_deadcode_remover_removes_middle_const_from_massign
        res = remove(<<~RB, "BAR")
          FOO, BAR, BAZ = 42
        RB

        assert_equal(<<~RB, res)
          FOO, BAZ = 42
        RB
      end

      def test_deadcode_remover_removes_last_const_from_massign
        res = remove(<<~RB, "BAZ")
          FOO, BAR, BAZ = 42
        RB

        assert_equal(<<~RB, res)
          FOO, BAR = 42
        RB
      end

      def test_deadcode_remover_removes_nested_massign
        res = remove(<<~RB, "BAR")
          class Foo
            # Some comment
            FOO, BAR, BAZ = T.let(42, Integer)
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            # Some comment
            FOO, BAZ = T.let(42, Integer)
          end
        RB
      end

      def test_deadcode_remover_removes_first_multiline_massign
        res = remove(<<~RB, "FOO")
          # Some comment
          FOO,
          BAR,
          BAZ = T.let(42, Integer)
        RB

        assert_equal(<<~RB, res)
          # Some comment
          BAR,
          BAZ = T.let(42, Integer)
        RB
      end

      def test_deadcode_remover_removes_middle_multiline_massign
        res = remove(<<~RB, "BAR")
          # Some comment
          FOO,
          BAR,
          BAZ = T.let(42, Integer)
        RB

        assert_equal(<<~RB, res)
          # Some comment
          FOO,
          BAZ = T.let(42, Integer)
        RB
      end

      def test_deadcode_remover_removes_last_multiline_massign
        res = remove(<<~RB, "BAZ")
          # Some comment
          FOO,
          BAR,
          BAZ = 42
        RB

        assert_equal(<<~RB, res)
          # Some comment
          FOO,
          BAR = 42
        RB
      end

      def test_deadcode_remover_removes_last_multiline_massign_with_comment
        res = remove(<<~RB, "BAR")
          # Some comment
          FOO,
          # Some other comment
          BAR,
          BAZ = T.let(42, Integer)
        RB

        assert_equal(<<~RB, res)
          # Some comment
          FOO,
          # Some other comment
          BAZ = T.let(42, Integer)
        RB
      end

      def test_deadcode_remover_removes_last_massign_one
        res = remove(<<~RB, "FOO")
          # Some comment
          FOO, = T.let(42, Integer)
        RB

        assert_empty(res)
      end

      def test_deadcode_remover_removes_first_const_from_massign_paren
        res = remove(<<~RB, "FOO")
          (FOO, BAR, BAZ) = 42
        RB

        assert_equal(<<~RB, res)
          (BAR, BAZ) = 42
        RB
      end

      def test_deadcode_remover_removes_middle_const_from_massign_paren
        res = remove(<<~RB, "BAR")
          (FOO, BAR, BAZ) = 42
        RB

        assert_equal(<<~RB, res)
          (FOO, BAZ) = 42
        RB
      end

      def test_deadcode_remover_removes_last_const_from_massign_paren
        res = remove(<<~RB, "BAZ")
          (FOO, BAR, BAZ) = 42
        RB

        assert_equal(<<~RB, res)
          (FOO, BAR) = 42
        RB
      end

      def test_deadcode_remover_removes_first_multiline_massign_paren
        res = remove(<<~RB, "FOO")
          # Some comment
          (FOO,
          BAR,
          BAZ) = T.let(42, Integer)
        RB

        assert_equal(<<~RB, res)
          # Some comment
          (BAR,
          BAZ) = T.let(42, Integer)
        RB
      end

      def test_deadcode_remover_removes_middle_multiline_massign_paren
        res = remove(<<~RB, "BAR")
          # Some comment
          (FOO,
          BAR,
          BAZ) = T.let(42, Integer)
        RB

        assert_equal(<<~RB, res)
          # Some comment
          (FOO,
          BAZ) = T.let(42, Integer)
        RB
      end

      def test_deadcode_remover_removes_last_multiline_massign_paren
        res = remove(<<~RB, "BAZ")
          # Some comment
          (FOO,
          BAR,
          BAZ) = 42
        RB

        assert_equal(<<~RB, res)
          # Some comment
          (FOO,
          BAR) = 42
        RB
      end

      def test_deadcode_remover_removes_last_multiline_massign_with_comment_paren
        res = remove(<<~RB, "BAR")
          # Some comment
          (
            FOO,
            # Some other comment
            BAR,
            BAZ,
          ) = T.let(42, Integer)
        RB

        assert_equal(<<~RB, res)
          # Some comment
          (
            FOO,
            # Some other comment
            BAZ,
          ) = T.let(42, Integer)
        RB
      end

      def test_deadcode_remover_removes_last_massign_one_paren
        res = remove(<<~RB, "FOO")
          (FOO,) = T.let(42, Integer)
        RB

        assert_empty(res)
      end

      def test_deadcode_remover_removes_first_class_of_root
        res = remove(<<~RB, "Foo")
          class Foo; end
          class Bar; end
          class Baz; end
        RB

        assert_equal(<<~RB, res)
          class Bar; end
          class Baz; end
        RB
      end

      def test_deadcode_remover_removes_middle_class_of_root
        res = remove(<<~RB, "Bar")
          class Foo; end
          class Bar; end
          class Baz; end
        RB

        assert_equal(<<~RB, res)
          class Foo; end
          class Baz; end
        RB
      end

      def test_deadcode_remover_removes_last_class_of_root
        res = remove(<<~RB, "Baz")
          class Foo; end
          class Bar; end
          class Baz; end
        RB

        assert_equal(<<~RB, res)
          class Foo; end
          class Bar; end
        RB
      end

      def test_deadcode_remover_removes_first_nested_class
        res = remove(<<~RB, "Bar")
          class Foo
            class Bar; end
            class Baz; end
            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Baz; end
            class Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_first_nested_class_with_blank_line_before
        res = remove(<<~RB, "Bar")
          class Foo

            class Bar; end
            class Baz; end
            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Baz; end
            class Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_middle_nested_class
        res = remove(<<~RB, "Baz")
          class Foo
            class Bar; end
            class Baz; end
            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Bar; end
            class Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_middle_nested_class_with_blank_line_before
        res = remove(<<~RB, "Baz")
          class Foo
            class Bar; end

            class Baz; end
            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Bar; end
            class Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_middle_nested_class_with_blank_line_after
        res = remove(<<~RB, "Baz")
          class Foo
            class Bar; end
            class Baz; end

            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Bar; end

            class Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_middle_nested_class_with_blank_lines
        res = remove(<<~RB, "Baz")
          class Foo
            class Bar; end

            class Baz; end

            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Bar; end

            class Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_last_nested_class
        res = remove(<<~RB, "Qux")
          class Foo
            class Bar; end
            class Baz; end
            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Bar; end
            class Baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_last_nested_class_with_blank_lines
        res = remove(<<~RB, "Qux")
          class Foo
            class Bar; end

            class Baz; end

            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Bar; end

            class Baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_nested_class_with_comments
        res = remove(<<~RB, "Baz")
          class Foo
            class Bar; end

            # Some
            # comment
            # for
            # Baz
            class Baz; end

            class Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class Bar; end

            class Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_first_module_of_root
        res = remove(<<~RB, "Foo")
          module Foo; end
          module Bar; end
          module Baz; end
        RB

        assert_equal(<<~RB, res)
          module Bar; end
          module Baz; end
        RB
      end

      def test_deadcode_remover_removes_middle_module_of_root
        res = remove(<<~RB, "Bar")
          module Foo; end
          module Bar; end
          module Baz; end
        RB

        assert_equal(<<~RB, res)
          module Foo; end
          module Baz; end
        RB
      end

      def test_deadcode_remover_removes_last_module_of_root
        res = remove(<<~RB, "Baz")
          module Foo; end
          module Bar; end
          module Baz; end
        RB

        assert_equal(<<~RB, res)
          module Foo; end
          module Bar; end
        RB
      end

      def test_deadcode_remover_removes_first_nested_module
        res = remove(<<~RB, "Bar")
          module Foo
            module Bar; end
            module Baz; end
            module Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          module Foo
            module Baz; end
            module Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_middle_nested_module
        res = remove(<<~RB, "Baz")
          module Foo
            module Bar; end
            module Baz; end
            module Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          module Foo
            module Bar; end
            module Qux; end
          end
        RB
      end

      def test_deadcode_remover_removes_last_nested_module
        res = remove(<<~RB, "Qux")
          module Foo
            module Bar; end
            module Baz; end
            module Qux; end
          end
        RB

        assert_equal(<<~RB, res)
          module Foo
            module Bar; end
            module Baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_first_def_of_root
        res = remove(<<~RB, "foo")
          def foo; end
          def bar; end
          def baz; end
        RB

        assert_equal(<<~RB, res)
          def bar; end
          def baz; end
        RB
      end

      def test_deadcode_remover_removes_middle_def_of_root
        res = remove(<<~RB, "bar")
          def foo; end
          def bar; end
          def baz; end
        RB

        assert_equal(<<~RB, res)
          def foo; end
          def baz; end
        RB
      end

      def test_deadcode_remover_removes_last_def_of_root
        res = remove(<<~RB, "baz")
          def foo; end
          def bar; end
          def baz; end
        RB

        assert_equal(<<~RB, res)
          def foo; end
          def bar; end
        RB
      end

      def test_deadcode_remover_removes_first_nested_def
        res = remove(<<~RB, "foo")
          class Foo
            def foo; end
            def bar; end
            def baz; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def bar; end
            def baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_middle_nested_def
        res = remove(<<~RB, "bar")
          class Foo
            def foo; end
            def bar; end
            def baz; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def foo; end
            def baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_last_nested_def
        res = remove(<<~RB, "baz")
          class Foo
            def foo; end
            def bar; end
            def baz; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def foo; end
            def bar; end
          end
        RB
      end

      def test_deadcode_remover_removes_def_in_module
        res = remove(<<~RB, "foo")
          module Foo
            def foo
              super
            end
          end

          module Bar; end
        RB

        assert_equal(<<~RB, res)
          module Foo
          end

          module Bar; end
        RB
      end

      def test_deadcode_remover_removes_node_with_blank_lines
        res = remove(<<~RB, "bar")
          class Foo
            def foo; end

            def bar
              something
            end

            def baz; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def foo; end

            def baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_node_with_comments
        res = remove(<<~RB, "bar")
          class Foo
            def foo; end

            # Some comments
            # related
            # to bar
            def bar
              something
            end

            def baz; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def foo; end

            def baz; end
          end
        RB
      end

      def test_deadcode_remover_does_not_remove_unrelated_comments
        res = remove(<<~RB, "bar")
          class Foo
            def foo; end

            # Some comments
            # unrelated
            # to bar

            def bar
              something
            end

            def baz; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def foo; end

            # Some comments
            # unrelated
            # to bar

            def baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_node_sig
        res = remove(<<~RB, "bar")
          class Foo
            def foo; end

            sig { void }
            def bar
              something
            end

            def baz; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def foo; end

            def baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_node_sig_and_comments
        res = remove(<<~RB, "bar")
          class Foo
            def foo; end

            # Some comments
            sig { void }
            # Some more comments
            def bar
              something
            end

            def baz; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def foo; end

            def baz; end
          end
        RB
      end

      def test_deadcode_remover_removes_singleton_class_if_needed
        res = remove(<<~RB, "foo")
          class Foo
            class << self
              def foo; end
            end

            def bar; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def bar; end
          end
        RB
      end

      def test_deadcode_remover_removes_singleton_class_when_it_contains_only_sorbet_related_nodes
        res = remove(<<~RB, "foo")
          class Foo
            class << self
              extend T::Sig

              sig { void }
              def foo; end
            end

            def bar; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            def bar; end
          end
        RB
      end

      def test_deadcode_remover_removes_method_from_singleton_class
        res = remove(<<~RB, "foo")
          class Foo
            class << self
              sig { void }
              def foo; end

              sig { void }
              def bar; end
            end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class << self
              sig { void }
              def bar; end
            end
          end
        RB
      end

      def test_deadcode_remover_does_not_remove_singleton_class_if_more_than_one_node
        res = remove(<<~RB, "foo")
          class Foo
            class << self
              def foo; end
              def bar; end
            end

            def bar; end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            class << self
              def bar; end
            end

            def bar; end
          end
        RB
      end

      def test_deadcode_remover_removes_attr_command
        res = remove(<<~RB, "foo")
          class Foo
            attr_reader :foo
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
          end
        RB
      end

      def test_deadcode_remover_removes_attr_command_with_comment
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader :foo
            # Some comment
            attr_reader :bar
            attr_reader :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :foo
            attr_reader :baz
          end
        RB
      end

      def test_deadcode_remover_removes_attr_command_with_sig
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader :foo
            sig { returns(Integer) }
            attr_reader :bar
            attr_reader :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :foo
            attr_reader :baz
          end
        RB
      end

      def test_deadcode_remover_removes_attr_command_with_sig_and_blank_lines
        res = remove(<<~RB, "foo")
          module Foo
            class Bar
              sig { returns(String) }
              attr_reader :foo

              sig { void }
              def initialize
              end
            end
          end
        RB

        assert_equal(<<~RB, res)
          module Foo
            class Bar
              sig { void }
              def initialize
              end
            end
          end
        RB
      end

      def test_deadcode_remover_removes_attr_command_with_comment_and_sig
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader :foo
            # Some comment
            sig { returns(Integer) }
            attr_reader :bar
            attr_reader :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :foo
            attr_reader :baz
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node
        res = remove(<<~RB, "foo")
          class Foo
            attr_reader(:foo)
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_with_comment
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader(:foo)
            # Some comment
            attr_reader(:bar)
            attr_reader(:baz)
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(:foo)
            attr_reader(:baz)
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_with_sig
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader(:foo)
            sig { returns(Integer) }
            attr_reader(:bar)
            attr_reader(:baz)
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(:foo)
            attr_reader(:baz)
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_with_comment_and_sig
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader(:foo)
            # Some comment
            sig { returns(Integer) }
            attr_reader(:bar)
            attr_reader(:baz)
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(:foo)
            attr_reader(:baz)
          end
        RB
      end

      def test_deadcode_remover_removes_attr_command_multiple_first
        res = remove(<<~RB, "foo")
          class Foo
            attr_reader :foo, :bar, :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :bar, :baz
          end
        RB
      end

      def test_deadcode_remover_removes_attr_command_multiple_middle
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader :foo, :bar, :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :foo, :baz
          end
        RB
      end

      def test_deadcode_remover_removes_attr_command_multiple_last
        res = remove(<<~RB, "baz")
          class Foo
            attr_reader :foo, :bar, :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :foo, :bar
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_multiple_first
        res = remove(<<~RB, "foo")
          class Foo
            attr_reader(:foo, :bar, :baz)
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(:bar, :baz)
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_multiple_middle
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader(:foo, :bar, :baz)
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(:foo, :baz)
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_multiple_last
        res = remove(<<~RB, "baz")
          class Foo
            attr_reader(:foo, :bar, :baz)
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(:foo, :bar)
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_multiline_first
        res = remove(<<~RB, "foo")
          class Foo
            attr_reader(
              :foo,
              :bar,
              :baz
            )
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(
              :bar,
              :baz
            )
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_multiline_middle
        res = remove(<<~RB, "bar")
          class Foo
            attr_reader(
              :foo,
              :bar,
              :baz
            )
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(
              :foo,
              :baz
            )
          end
        RB
      end

      def test_deadcode_remover_removes_attr_call_node_multiline_last
        res = remove(<<~RB, "baz")
          class Foo
            attr_reader(
              :foo,
              :bar,
              :baz
            )
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader(
              :foo,
              :bar
            )
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_line_and_adds_reader
        res = remove(<<~RB, "foo=")
          class Foo
            attr_accessor :foo
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :foo
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_line_and_adds_writer
        res = remove(<<~RB, "foo")
          class Foo
            attr_reader :bar
            attr_accessor :foo
            attr_writer :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :bar

            attr_writer :foo

            attr_writer :baz
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_symbol_and_adds_reader
        res = remove(<<~RB, "foo=")
          class Foo
            attr_accessor :foo, :bar
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_accessor :bar

            attr_reader :foo
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_symbol_and_adds_writer
        res = remove(<<~RB, "baz=")
          class Foo
            attr_reader :foo
            attr_accessor :bar, :baz
            attr_writer :qux
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            attr_reader :foo
            attr_accessor :bar

            attr_reader :baz

            attr_writer :qux
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_symbol_and_adds_reader_with_sig
        res = remove(<<~RB, "foo=")
          class Foo
            sig { returns(Integer) }
            attr_accessor :foo, :bar
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            sig { returns(Integer) }
            attr_accessor :bar

            sig { returns(Integer) }
            attr_reader :foo
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_symbol_and_adds_writer_with_sig
        res = remove(<<~RB, "foo")
          class Foo
            sig { returns(Integer) }
            attr_accessor :foo, :bar
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            sig { returns(Integer) }
            attr_accessor :bar

            sig { params(foo: Integer).returns(Integer) }
            attr_writer :foo
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_symbol_and_adds_reader_with_sig_handles_newlines
        res = remove(<<~RB, "foo=")
          class Foo
            sig { returns(Integer) }
            attr_accessor :foo, :bar

            sig { returns(String) }
            attr_accessor :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            sig { returns(Integer) }
            attr_accessor :bar

            sig { returns(Integer) }
            attr_reader :foo

            sig { returns(String) }
            attr_accessor :baz
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_symbol_and_adds_reader_with_block_sig
        res = remove(<<~RB, "foo=")
          class Foo
            sig do
              returns(Integer)
            end
            attr_accessor :foo, :bar

            sig { returns(String) }
            attr_accessor :baz
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            sig do
              returns(Integer)
            end
            attr_accessor :bar

            sig { returns(Integer) }
            attr_reader :foo

            sig { returns(String) }
            attr_accessor :baz
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_symbol_and_adds_reader_with_other_code_around
        res = remove(<<~RB, "foo=")
          class Foo
            extend T::Sig

            sig { returns(Foo) }
            attr_accessor :foo

            sig { void }
            def initialize
            end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            extend T::Sig

            sig { returns(Foo) }
            attr_reader :foo

            sig { void }
            def initialize
            end
          end
        RB
      end

      def test_deadcode_remover_removes_attr_accessor_symbol_and_adds_reader_in_private_section
        res = remove(<<~RB, "foo=")
          class Foo
            extend T::Sig

            sig { void }
            def initialize
            end

            private

            sig { returns(Foo) }
            attr_accessor :foo

            def foo
            end
          end
        RB

        assert_equal(<<~RB, res)
          class Foo
            extend T::Sig

            sig { void }
            def initialize
            end

            private

            sig { returns(Foo) }
            attr_reader :foo

            def foo
            end
          end
        RB
      end

      private

      sig { params(ruby_string: String, def_name: String).returns(String) }
      def remove(ruby_string, def_name)
        file = "file.rb"
        context = Context.mktmp!
        context.write!(file, ruby_string)

        model = Model.new
        ast = Spoom.parse_ruby(ruby_string, file: file)
        Model::Builder.new(model, file).visit(ast)

        index = Index.new(model)
        Deadcode.index_ruby(index, ruby_string, file: file)
        index.finalize!

        definitions = definitions_for_name(index, def_name)
        assert_equal(1, definitions.size) # We only support one def by name in these tests
        definition = T.must(definitions.first)

        remover = Remover.new(context)
        new_source = remover.remove_location(definition.kind, definition.location)

        context.destroy!

        new_source
      end
    end
  end
end
