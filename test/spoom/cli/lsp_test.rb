# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    class LSPTest < TestWithProject
      def setup
        @project.bundle_install!
      end

      # Errors

      def test_cant_open_without_config
        @project.remove!("sorbet/config")
        result = @project.spoom("lsp --no-color find Foo")
        assert_empty(result.out)
        assert_equal("Error: not in a Sorbet project (`sorbet/config` not found)", result.err&.lines&.first&.chomp)
        refute(result.status)
      end

      def test_cant_open_with_errors
        @project.write!("errors.rb", <<~RB)
          # typed: true

          class Foo
            sig { params(a: String).returns(String) }
            def foo(a)
            end
          end

          Foo.new.foo
          Bar.new.bar
        RB
        result = @project.spoom("lsp --no-color find Foo")
        assert_equal(<<~MSG, result.err)
          Error: Sorbet returned typechecking errors for `/errors.rb`
            8:11-8:11: Not enough arguments provided for method `Foo#foo`. Expected: `1`, got: `0` (7004)
            5:2-5:5: Expected `String` but found `NilClass` for method result type (7005)
            3:2-3:5: Method `sig` does not exist on `T.class_of(Foo)` (fix available) (7003)
            3:8-3:14: Method `params` does not exist on `T.class_of(Foo)` (7003)
            9:0-9:3: Unable to resolve constant `Bar` (fix available) (5002)
        MSG
      end

      # Defs

      def test_list_defs
        @project.write!("lib/defs.rb", <<~RB)
          # typed: true
          # frozen_string_literal: true

          adef = ARGV.first
          puts adef
        RB
        result = @project.spoom("lsp --no-color defs lib/defs.rb 3 6")
        assert_equal(<<~MSG, result.out)
          Definitions for `lib/defs.rb:3:6`:
            * /lib/defs.rb:3:7-3:17
        MSG
      end

      # Hover

      def test_list_hover_empty
        @project.write!("lib/hover.rb")
        result = @project.spoom("lsp --no-color hover lib/hover.rb 0 0")
        assert_equal(<<~MSG, result.out)
          Hovering `lib/hover.rb:0:0`:
          This file is `# typed: false`.
          Hover, Go To Definition, and other features are disabled in this file.
        MSG
      end

      def test_list_hover_class
        @project.write!("lib/hover.rb", <<~RB)
          # typed: true

          class HoverTest; end
        RB
        result = @project.spoom("lsp --no-color hover lib/hover.rb 2 12")
        assert_equal(<<~MSG, result.out)
          Hovering `lib/hover.rb:2:12`:
          T.class_of(HoverTest)
        MSG
      end

      def test_list_hover_def
        @project.write!("lib/hover.rb", <<~RB)
          # typed: true

          class HoverTest
            extend T::Sig

            sig { params(a: Integer).returns(String) }
            def foo(a)
              a.to_s
            end
          end
        RB
        result = @project.spoom("lsp --no-color hover lib/hover.rb 6 8")
        assert_equal(<<~MSG, result.out)
          Hovering `lib/hover.rb:6:8`:
          sig {params(a: Integer).returns(String)}
          def foo(a); end
        MSG
      end

      def test_list_hover_param
        @project.write!("lib/hover.rb", <<~RB)
          # typed: true

          class HoverTest
            extend T::Sig

            sig { params(a: Integer).returns(String) }
            def foo(a)
              a.to_s
            end
          end
        RB
        result = @project.spoom("lsp --no-color hover lib/hover.rb 6 11")
        assert_equal(<<~MSG, result.out)
          Hovering `lib/hover.rb:6:11`:
          Integer
        MSG
      end

      def test_list_hover_call
        @project.write!("lib/hover.rb", <<~RB)
          # typed: true

          class HoverTest
            extend T::Sig

            sig { params(a: Integer).returns(String) }
            def foo(a)
              a.to_s
            end
          end

          ht = HoverTest.new
          ht.foo(42)
        RB
        result = @project.spoom("lsp --no-color hover lib/hover.rb 12 4")
        assert_equal(<<~MSG, result.out)
          Hovering `lib/hover.rb:12:4`:
          sig {params(a: Integer).returns(String)}
          def foo(a); end
        MSG
      end

      # Find

      def test_find
        @project.write!("lib/find.rb", <<~RB)
          # typed: true

          class Test; end
        RB
        result = @project.spoom("lsp --no-color find Test")
        assert_equal(<<~MSG, result.out)
          Symbols matching `Test`:
            class Test (/lib/find.rb:2:0-2:10)
        MSG
      end

      # Refs

      def test_list_refs
        @project.write!("lib/refs.rb", <<~RB)
          # typed: true

          ref = ARGV.first
          ref = ref.downcase
          ref.sub!("name", "Alex")
          puts ref
        RB
        result = @project.spoom("lsp --no-color refs lib/refs.rb 2 1")
        assert_equal(<<~MSG, result.out)
          References to `lib/refs.rb:2:1`:
            * /lib/refs.rb:2:0-2:3
            * /lib/refs.rb:3:0-3:3
            * /lib/refs.rb:3:6-3:9
            * /lib/refs.rb:4:0-4:3
            * /lib/refs.rb:5:5-5:8
        MSG
      end

      # Sigs

      def test_list_sigs
        @project.write!("lib/sigs.rb", <<~RB)
          # typed: true

          class SigsTest
            extend T::Sig

            sig { params(a: Integer).returns(String) }
            def bar(a)
              a.to_s
            end
          end

          y = SigsTest.new
          y.bar(42)
        RB
        result = @project.spoom("lsp --no-color sigs lib/sigs.rb 12 4")
        assert_equal(<<~MSG, result.out)
          Signature for `lib/sigs.rb:12:4`:
            * SigsTest#bar(a: Integer, <blk>: T.untyped)
        MSG
      end

      # Symbols

      def test_list_symbols
        @project.write!("lib/symbols.rb", <<~RB)
          # typed: true

          module Symbols
            class A
              attr_reader :a, :b

              def foo; end

              def bar; end

              def self.baz; end
            end

            class B < A
              include Symbols
              class C; end
            end
          end

          module OtherModule; end
          class OtherClass; end
        RB
        result = @project.spoom("lsp --no-color symbols lib/symbols.rb")
        assert_equal(<<~MSG, result.out)
          Symbols from `lib/symbols.rb`:
            module Symbols (2:0-17:3)
              class A (3:2-11:5)
                property a (4:4-4:22)
                property b (4:4-4:22)
                def bar (8:4-8:16)
                def foo (6:4-6:16)
                def self.baz (10:4-10:21)
              class B (13:2-16:5)
                class C (15:4-15:16)
            module OtherModule (19:0-19:23)
            class OtherClass (20:0-20:21)
        MSG
      end

      # Types

      def test_list_types
        @project.write!("lib/types.rb", <<~RB)
          # typed: true

          class SomeType
          end

          a = SomeType.new
          puts a
        RB
        result = @project.spoom("lsp --no-color types lib/types.rb 5 5")
        assert_equal(<<~MSG, result.out)
          Type for `lib/types.rb:5:5`:
            * /lib/types.rb:2:0-2:14
        MSG
      end

      # --path

      def test_lsp_with_path_option
        @project.write!("lib/find.rb", <<~RB)
          # typed: true

          class Test; end
        RB
        project = new_project("test_lsp_with_path_option_2")
        project.bundle_install!
        result = project.spoom("lsp -p #{@project.absolute_path} --no-color find Test")
        assert_equal(<<~MSG, result.out)
          Symbols matching `Test`:
            class Test (/lib/find.rb:2:0-2:10)
        MSG
        project.destroy!
      end
    end
  end
end
