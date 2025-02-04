# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Stubs
    class CheckerTest < TestWithProject
      def setup
        @project.write!("mock_framework.rb", <<~RB)
          # typed: true

          module Mocha
            extend T::Sig

            sig { returns(T.self_type) }
            def any_instance
              self
            end

            sig { params(method: Symbol).returns(T.self_type) }
            def expects(method)
              self
            end

            sig { params(args: T.untyped).returns(T.self_type) }
            def with(*args)
              self
            end

            sig { params(res: T.untyped).returns(T.self_type) }
            def returns(res)
              self
            end
          end

          class Object
            extend Mocha
          end

          class Foo; end
        RB

        lsp_client = Spoom::LSPClient.new(
          Spoom::Sorbet::BIN_PATH,
          "--no-config",
          "--lsp",
          "--disable-watchman",
          "-v",
          "-v",
          # "-v",
          @project.absolute_path,
        )

        lsp_client.request("initialize", {
          rootPath: @project.absolute_path,
          rootUri: "file://#{@project.absolute_path}",
          capabilities: {},
        })

        lsp_client.notify("initialized", {})
        @checker = Spoom::Stubs::Checker.new(@project.absolute_path, lsp_client, with_location: false)
      end

      # scopes

      def test_scope_top_level
        test = <<~RB
          test "some test" do
            Foo.expects(:foo).returns(true)
          end
        RB

        assert_snippet(<<~RB, snippet(test))
          extend T::Sig

          sig { params(recv: T.class_of(Foo), ret: T::Boolean).void }
          def check_stub(recv, ret)
            res = recv.foo()
            [].each { res = ret }
          end
        RB
      end

      def test_scope_one
        test = <<~RB
          class MockTest
            test "some test" do
              Foo.expects(:foo).returns(true)
            end
          end
        RB

        assert_snippet(<<~RB, snippet(test))
          class MockTest
            extend T::Sig

            sig { params(recv: T.class_of(Foo), ret: T::Boolean).void }
            def check_stub(recv, ret)
              res = recv.foo()
              [].each { res = ret }
            end
          end
        RB
      end

      def test_scope_nested
        test = <<~RB
          module Foo
            class MockTest
              test "some test" do
                Foo.expects(:foo).returns(true)
              end
            end
          end
        RB

        assert_snippet(<<~RB, snippet(test))
          module Foo
            class MockTest
              extend T::Sig

              sig { params(recv: T.class_of(Foo), ret: T::Boolean).void }
              def check_stub(recv, ret)
                res = recv.foo()
                [].each { res = ret }
              end
            end
          end
        RB
      end

      # method

      def test_method_instance
        test = <<~RB
          test "some test" do
            Foo.any_instance.expects(:foo).returns(true)
          end
        RB

        assert_snippet(<<~RB, snippet(test))
          extend T::Sig

          sig { params(recv: Foo, ret: T::Boolean).void }
          def check_stub(recv, ret)
            res = recv.foo()
            [].each { res = ret }
          end
        RB
      end

      def test_method_singleton
        test = <<~RB
          test "some test" do
            Foo.expects(:foo).returns(true)
          end
        RB

        assert_snippet(<<~RB, snippet(test))
          extend T::Sig

          sig { params(recv: T.class_of(Foo), ret: T::Boolean).void }
          def check_stub(recv, ret)
            res = recv.foo()
            [].each { res = ret }
          end
        RB
      end

      # return type

      def test_return_type_untyped
        test = <<~RB
          def bar; end

          test "some test" do
            Foo.expects(:foo).returns(bar)
          end
        RB

        assert_snippet(<<~RB, snippet(test))
          extend T::Sig

          sig { params(recv: T.class_of(Foo), ret: T::Boolean).void }
          def check_stub(recv, ret)
            res = recv.foo()
            [].each { res = ret }
          end
        RB
      end

      def test_with_arguments
        test = <<~RB
          class MockTest
            test "some test" do
              Foo.expects(:foo).with(1, 2, 3).returns(true)
            end
          end
        RB

        assert_snippet(<<~RB, snippet(test))
          class MockTest
            extend T::Sig

            sig { params(recv: T.class_of(Foo), arg1: Integer, arg2: Integer, arg3: Integer, ret: T::Boolean).void }
            def check_stub(recv, arg1, arg2, arg3, ret)
              res = recv.foo(arg1, arg2, arg3)
              [].each { res = ret }
            end
          end
        RB
      end

      private

      sig { params(ruby: String).returns(String) }
      def snippet(ruby)
        ruby = <<~RB
          # typed: true

          #{ruby}
        RB

        file = "some_test.rb"
        @project.write!(file, ruby)
        path = @project.absolute_path_to(file)
        node = Spoom.parse_ruby(ruby, file: path)
        visitor = Spoom::Stubs::Collector.new(file)
        visitor.visit(node)
        stub = T.must(visitor.stubs.first)

        @checker.generate_snippet(stub)
      end

      def assert_snippet(expected, actual)
        assert_equal(<<~RB, actual.gsub(/check_stub_[0-9]+/, "check_stub"))
          # typed: strict
          # frozen_string_literal: true

          #{expected.rstrip}
        RB
      end
    end
  end
end
