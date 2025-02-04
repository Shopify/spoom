# typed: true
# frozen_string_literal: true

require "test_with_project"

module Spoom
  module Cli
    class StubsTest < TestWithProject
      def setup
        @project.bundle_install!
        @project.write!("mock_framework.rb", <<~RB)
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
        RB
      end

      def test_stubs_check_empty
        result = @project.spoom("stubs check --no-color")
        assert_equal(<<~ERR, result.err)
          Error: No test files to check
        ERR
        refute(result.status)
      end

      def test_stubs_check_expect_singleton_method
        @project.write!("test/foo_test.rb", <<~RB)
          class Foo
            def self.foo; end
          end

          class MockTest
            extend T::Sig

            test "some test" do
              Foo.expects(:foo).returns(true)
            end
          end
        RB

        result = @project.spoom("stubs check --no-color")
        assert_includes(result.out, <<~OUT)
          Checking `1` stubs...
          Generating snippet for stub `1/1`
          Generated `1` snippets
          Running type checking...
          Found `0` errors
        OUT
        assert(result.status)
      end

      def test_stubs_check_expect_instance_method
        @project.write!("test/foo_test.rb", <<~RB)
          class Foo
            def foo; end
          end

          class MockTest
            extend T::Sig
            test "some test" do
              Foo.any_instance.expects(:foo).returns(true)
            end
          end
        RB

        result = @project.spoom("stubs check --no-color")
        assert_includes(result.out, <<~OUT)
          Checking `1` stubs...
          Generating snippet for stub `1/1`
          Generated `1` snippets
          Running type checking...
          Found `0` errors
        OUT
        assert(result.status)
      end
    end
  end
end
