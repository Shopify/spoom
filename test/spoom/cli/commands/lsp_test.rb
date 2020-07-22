# typed: true
# frozen_string_literal: true

require "pathname"

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class LSPTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        PROJECT = "project"

        before_all do
          install_sorbet(PROJECT)
        end

        def setup
          use_sorbet_config(PROJECT, <<~CFG)
            .
            --ignore=errors
          CFG
        end

        def teardown
          use_sorbet_config(PROJECT, nil)
        end

        # Errors

        def test_cant_open_without_config
          use_sorbet_config(PROJECT, nil)
          _, err = run_cli(PROJECT, "lsp --no-color find Foo")
          assert_equal(<<~MSG, err)
            Error: not in a Sorbet project (no sorbet/config)
          MSG
        end

        def test_cant_open_with_errors
          use_sorbet_config(PROJECT, "errors")
          _, err = run_cli(PROJECT, "lsp --no-color find Foo")
          assert_equal(<<~MSG, err)
            Error: Sorbet returned typechecking errors for `/errors.rb`
              9:4-9:15: Wrong number of arguments for constructor. Expected: `0`, got: `1` (7004)
              10:9-10:10: Method `c` does not exist on `T.class_of(<root>)` (7003)
              10:0-10:11: Too many arguments provided for method `Foo#foo`. Expected: `1`, got: `2` (7004)
              4:2-4:37: Method `sig` does not exist on `T.class_of(Foo)` (7003)
              4:8-4:24: Method `params` does not exist on `T.class_of(Foo)` (7003)
              4:20-4:23: Unable to resolve constant `Bar` (5002)
              4:33-4:34: Unable to resolve constant `C` (fix available) (5002)
          MSG
        end

        # Defs

        def test_list_defs
          out, _ = run_cli(PROJECT, "lsp --no-color defs lib/defs.rb 3 6")
          assert_equal(<<~MSG, out)
            Definitions for `lib/defs.rb:3:6`:
             * /lib/defs.rb:3:7-3:17
          MSG
        end

        # Hover

        def test_list_hover_empty
          out, _ = run_cli(PROJECT, "lsp --no-color hover lib/hover.rb 0 0")
          assert_equal(<<~MSG, out)
            Hovering `lib/hover.rb:0:0`:
            <no data>
          MSG
        end

        def test_list_hover_class
          out, _ = run_cli(PROJECT, "lsp --no-color hover lib/hover.rb 3 12")
          assert_equal(<<~MSG, out)
            Hovering `lib/hover.rb:3:12`:
            T.class_of(HoverTest)
          MSG
        end

        def test_list_hover_def
          out, _ = run_cli(PROJECT, "lsp --no-color hover lib/hover.rb 7 8")
          assert_equal(<<~MSG, out)
            Hovering `lib/hover.rb:7:8`:
            sig {params(a: Integer).returns(String)}
            def foo(a); end
          MSG
        end

        def test_list_hover_param
          out, _ = run_cli(PROJECT, "lsp --no-color hover lib/hover.rb 7 11")
          assert_equal(<<~MSG, out)
            Hovering `lib/hover.rb:7:11`:
            Integer
          MSG
        end

        def test_list_hover_call
          out, _ = run_cli(PROJECT, "lsp hover lib/hover.rb 13 4")
          assert_equal(<<~MSG, out)
            Hovering `lib/hover.rb:13:4`:
            sig {params(a: Integer).returns(String)}
            def foo(a); end
          MSG
        end

        # Find

        def test_find
          out, _ = run_cli(PROJECT, "lsp --no-color find Hover")
          assert_equal(<<~MSG, out)
            Symbols matching `Hover`:
              class HoverTest (/lib/hover.rb:3:0-3:15)
          MSG
        end

        # Refs

        def test_list_refs
          out, _ = run_cli(PROJECT, "lsp --no-color refs lib/refs.rb 2 1")
          assert_equal(<<~MSG, out)
            References to `lib/refs.rb:2:1`:
             * /lib/refs.rb:3:0-3:3
             * /lib/refs.rb:4:0-4:3
             * /lib/refs.rb:4:6-4:9
             * /lib/refs.rb:5:0-5:3
             * /lib/refs.rb:6:5-6:8
          MSG
        end

        # Sigs

        def test_list_sigs
          out, _ = run_cli(PROJECT, "lsp --no-color sigs lib/sigs.rb 13 4")
          assert_equal(<<~MSG, out)
            Signature for `lib/sigs.rb:13:4`:
             * SigsTest#bar(a: Integer, <blk>: T.untyped)
          MSG
        end

        # Symbols

        def test_list_symbols
          out, _ = run_cli(PROJECT, "lsp --no-color symbols lib/symbols.rb")
          assert_equal(<<~MSG, out)
            Symbols from `lib/symbols.rb`:
              module Symbols (3:0-3:14)
                class A (4:2-4:9)
                  def a (5:4-5:22)
                  def b (5:4-5:22)
                  def bar (9:4-9:11)
                  def foo (7:4-7:11)
                  def self.baz (11:4-11:16)
                class B (14:2-14:13)
                  class C (16:4-16:11)
              module OtherModule (20:0-20:18)
              class OtherClass (21:0-21:16)
          MSG
        end

        # Types

        def test_list_types
          out, _ = run_cli(PROJECT, "lsp --no-color types lib/types.rb 6 5")
          assert_equal(<<~MSG, out)
            Type for `lib/types.rb:6:5`:
             * /lib/types.rb:3:6-3:14
          MSG
        end
      end
    end
  end
end
