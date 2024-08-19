# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class CFGTest < Minitest::Test
    extend T::Sig

    def test_empty
      cluster = parse("")

      # Only one basic block in the cluster: the one for <main>
      assert_equal(1, cluster.cfgs.size)

      # A CFG as always at least two blocks: the entry block and the exit block
      cfg = T.must(cluster.cfgs.first)
      assert_equal(2, cfg.blocks.size)
    end

    def test_top_level_instructions
      cluster = parse(<<~RB)
        puts "foo"
        puts "bar"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("foo")
            <self>.puts("bar")
            -> bb#1

          bb#1
      CFG
    end

    def test_static_init
      cluster = parse(<<~RB)
        class Foo
          puts "foo"
          class Bar
            puts "bar"
            class << self
              puts "self"
              def foo; end
              private def bar; end
              puts "/self"
            end
            puts "/bar"
          end
          puts "/foo"
        end
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            class Foo
            -> bb#1

          bb#1

        cfg: Foo::<static-init>

          bb#0
            <self>.puts("foo")
            class Bar
            <self>.puts("/foo")
            -> bb#1

          bb#1

        cfg: Bar::<static-init>

          bb#0
            <self>.puts("bar")
            class << self
            <self>.puts("/bar")
            -> bb#1

          bb#1

        cfg: class << self::<static-init>

          bb#0
            <self>.puts("self")
            def foo
            <self>.private(def bar; end)
            <self>.puts("/self")
            -> bb#1

          bb#1

        cfg: foo

          bb#0
            -> bb#1

          bb#1

        cfg: bar

          bb#0
            -> bb#1

          bb#1
      CFG
    end

    def test_break_for
      cluster = parse(<<~RB)
        puts "before"
        for i in foo
          puts "foo"
          break if bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo()
            -> bb#2

          bb#2
            i
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            <self>.bar?()
            -> bb#5
            -> bb#7

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            break
            -> bb#4

          bb#7
            <self>.puts("bar")
            -> bb#2

          bb#1
      CFG
    end

    def test_break_until
      cluster = parse(<<~RB)
        puts "before"
        until foo?
          puts "foo"
          break if bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            -> bb#2

          bb#2
            <self>.foo?()
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            <self>.bar?()
            -> bb#5
            -> bb#7

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            break
            -> bb#4

          bb#7
            <self>.puts("bar")
            -> bb#2

          bb#1
      CFG
    end

    def test_break_while
      cluster = parse(<<~RB)
        puts "before"
        while foo?
          puts "foo"
          break if bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            -> bb#2

          bb#2
            <self>.foo?()
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            <self>.bar?()
            -> bb#5
            -> bb#7

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            break
            -> bb#4

          bb#7
            <self>.puts("bar")
            -> bb#2

          bb#1
      CFG
    end

    def test_break_dead
      cluster = parse(<<~RB)
        while true
          puts "before"
          break "break"
          puts "dead"
        end
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            -> bb#3
            -> bb#1

          bb#3
            <self>.puts("before")
            break "break"
            -> bb#5
            -> bb#1

          bb#1

          bb#5
            <self>.puts("dead")
      CFG
    end

    def test_case_when
      cluster = parse(<<~RB)
        puts "before"
        case foo
        when 1
          puts "one"
        when 2
          puts "two"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo()
            -> bb#3
            -> bb#4
            -> bb#2

          bb#3
            <self>.puts("one")
            -> bb#2

          bb#4
            <self>.puts("two")
            -> bb#2

          bb#2
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_case_else
      cluster = parse(<<~RB)
        case foo
        when 1
          puts "one"
        when 2
          puts "two"
        else
          puts "else"
        end
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.foo()
            -> bb#3
            -> bb#4
            -> bb#5

          bb#3
            <self>.puts("one")
            -> bb#1

          bb#4
            <self>.puts("two")
            -> bb#1

          bb#5
            <self>.puts("else")
            -> bb#1

          bb#1
      CFG
    end

    def test_call_block
      cluster = parse(<<~RB)
        puts "before"
        foo { puts "inside" }
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo()
            -> bb#2

          bb#2
            <block-call>
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("inside")
            -> bb#2

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_call_block_next
      cluster = parse(<<~RB)
        def foo
          [1].map do |x|
            good # error: Method `good` does not exist on `Object`
            next x
            bad
          # ^^^ error: This expression appears after an unconditional return
          end
        end
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            def foo
            -> bb#1

          bb#1

        cfg: foo

          bb#0
            [1].map()
            -> bb#2

          bb#2
            <block-call>
            -> bb#3
            -> bb#1

          bb#3
            <self>.good()
            next x
            -> bb#2
            -> bb#4

          bb#1

          bb#4
            <self>.bad()
      CFG
    end

    def test_call_block_return
      cluster = parse(<<~RB)
        puts "before"
        foo do |x|
          if foo?
            puts "will return"
            return x
            puts "dead"
          end
          puts "after return"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo()
            -> bb#2

          bb#2
            <block-call>
            -> bb#3
            -> bb#8

          bb#3
            <self>.foo?()
            -> bb#4
            -> bb#6

          bb#8
            <self>.puts("after")
            -> bb#1

          bb#4
            <self>.puts("will return")
            return x
            -> bb#1
            -> bb#7

          bb#6
            <self>.puts("after return")
            -> bb#2

          bb#1

          bb#7
            <self>.puts("dead")
      CFG
    end

    def test_def
      cluster = parse(<<~RB)
        puts "before"
        def foo
          puts "foo"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            def foo
            <self>.puts("after")
            -> bb#1

          bb#1

        cfg: foo

          bb#0
            <self>.puts("foo")
            -> bb#1

          bb#1
      CFG
    end

    def test_for
      cluster = parse(<<~RB)
        puts "before"
        for i in foo
          puts "foo"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo()
            -> bb#2

          bb#2
            i
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            -> bb#2

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_if
      cluster = parse(<<~RB)
        puts "before"
        if foo?
          puts "foo"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo?()
            -> bb#2
            -> bb#4

          bb#2
            <self>.puts("foo")
            -> bb#4

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_if_inline
      cluster = parse(<<~RB)
        puts "before"
        puts "foo" if foo?
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo?()
            -> bb#2
            -> bb#4

          bb#2
            <self>.puts("foo")
            -> bb#4

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_if_else
      cluster = parse(<<~RB)
        puts "before"
        if foo?
          puts "foo"
        else
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo?()
            -> bb#2
            -> bb#3

          bb#2
            <self>.puts("foo")
            -> bb#4

          bb#3
            <self>.puts("bar")
            -> bb#4

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_if_elsif
      cluster = parse(<<~RB)
        puts "before"
        if foo?
          puts "foo"
        elsif bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo?()
            -> bb#2
            -> bb#3

          bb#2
            <self>.puts("foo")
            -> bb#4

          bb#3
            <self>.bar?()
            -> bb#5
            -> bb#4

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            <self>.puts("bar")
            -> bb#4

          bb#1
      CFG
    end

    def test_if_elsif_else
      cluster = parse(<<~RB)
        puts "before"
        if foo?
          puts "foo"
        elsif bar?
          puts "bar"
        else
          puts "baz"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo?()
            -> bb#2
            -> bb#3

          bb#2
            <self>.puts("foo")
            -> bb#4

          bb#3
            <self>.bar?()
            -> bb#5
            -> bb#6

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            <self>.puts("bar")
            -> bb#4

          bb#6
            <self>.puts("baz")
            -> bb#4

          bb#1
      CFG
    end

    def test_next_for
      cluster = parse(<<~RB)
        puts "before"
        for i in foo
          puts "foo"
          next if bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo()
            -> bb#2

          bb#2
            i
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            <self>.bar?()
            -> bb#5
            -> bb#7

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            next
            -> bb#2

          bb#7
            <self>.puts("bar")
            -> bb#2

          bb#1
      CFG
    end

    def test_next_until
      cluster = parse(<<~RB)
        puts "before"
        until foo?
          puts "foo"
          next if bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            -> bb#2

          bb#2
            <self>.foo?()
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            <self>.bar?()
            -> bb#5
            -> bb#7

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            next
            -> bb#2

          bb#7
            <self>.puts("bar")
            -> bb#2

          bb#1
      CFG
    end

    def test_next_while
      cluster = parse(<<~RB)
        puts "before"
        while foo?
          puts "foo"
          next if bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            -> bb#2

          bb#2
            <self>.foo?()
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            <self>.bar?()
            -> bb#5
            -> bb#7

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            next
            -> bb#2

          bb#7
            <self>.puts("bar")
            -> bb#2

          bb#1
      CFG
    end

    def test_unless
      cluster = parse(<<~RB)
        puts "before"
        unless foo?
          puts "foo"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo?()
            -> bb#2
            -> bb#4

          bb#2
            <self>.puts("foo")
            -> bb#4

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_unless_inline
      cluster = parse(<<~RB)
        puts "before"
        puts "foo" unless foo?
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo?()
            -> bb#2
            -> bb#4

          bb#2
            <self>.puts("foo")
            -> bb#4

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_unless_else
      cluster = parse(<<~RB)
        puts "before"
        unless foo?
          puts "foo"
        else
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.foo?()
            -> bb#2
            -> bb#3

          bb#2
            <self>.puts("foo")
            -> bb#4

          bb#3
            <self>.puts("bar")
            -> bb#4

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_until
      cluster = parse(<<~RB)
        puts "before"
        until foo?
          puts "foo"

          puts "bar" until bar?
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            -> bb#2

          bb#2
            <self>.foo?()
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            -> bb#5

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            <self>.bar?()
            -> bb#6
            -> bb#2

          bb#1

          bb#6
            <self>.puts("bar")
            -> bb#5
      CFG
    end

    def test_while
      cluster = parse(<<~RB)
        puts "before"
        while foo?
          puts "foo"

          puts "bar" while bar?
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            -> bb#2

          bb#2
            <self>.foo?()
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            -> bb#5

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            <self>.bar?()
            -> bb#6
            -> bb#2

          bb#1

          bb#6
            <self>.puts("bar")
            -> bb#5
      CFG
    end

    def test_yield
      cluster = parse(<<~RB)
        def foo
          puts "before"
          yield
          puts "after"
        end
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            def foo
            -> bb#1

          bb#1

        cfg: foo

          bb#0
            <self>.puts("before")
            yield
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_return
      cluster = parse(<<~RB)
        puts "before"
        def foo
          puts "before"
          return
          puts "dead"
        end

        return
        puts "dead2"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            def foo
            return
            -> bb#1
            -> bb#2

          bb#1

          bb#2
            <self>.puts("dead2")

        cfg: foo

          bb#0
            <self>.puts("before")
            return
            -> bb#1
            -> bb#2

          bb#1

          bb#2
            <self>.puts("dead")
      CFG
    end

    def test_return_case
      cluster = parse(<<~RB)
        puts "before"
        case bar
        when 1
          return
        else
          puts "else"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.bar()
            -> bb#3
            -> bb#5

          bb#3
            return
            -> bb#1

          bb#5
            <self>.puts("else")
            -> bb#2

          bb#1

          bb#2
            <self>.puts("after")
            -> bb#1
      CFG
    end

    def test_return_if
      cluster = parse(<<~RB)
        puts "before"
        return if bar?
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.bar?()
            -> bb#2
            -> bb#4

          bb#2
            return
            -> bb#1

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_return_if_else
      cluster = parse(<<~RB)
        puts "before"
        if bar?
          puts "bar"
        else
          return
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            <self>.bar?()
            -> bb#2
            -> bb#3

          bb#2
            <self>.puts("bar")
            -> bb#4

          bb#3
            return
            -> bb#1

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#1
      CFG
    end

    def test_return_until
      cluster = parse(<<~RB)
        puts "before"
        until foo?
          puts "foo"
          return if bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            -> bb#2

          bb#2
            <self>.foo?()
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            <self>.bar?()
            -> bb#5
            -> bb#7

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            return
            -> bb#1

          bb#7
            <self>.puts("bar")
            -> bb#2

          bb#1
      CFG
    end

    def test_return_while
      cluster = parse(<<~RB)
        puts "before"
        while foo?
          puts "foo"
          return if bar?
          puts "bar"
        end
        puts "after"
      RB

      assert_equal(<<~CFG, cluster.inspect)
        cfg: <main>

          bb#0
            <self>.puts("before")
            -> bb#2

          bb#2
            <self>.foo?()
            -> bb#3
            -> bb#4

          bb#3
            <self>.puts("foo")
            <self>.bar?()
            -> bb#5
            -> bb#7

          bb#4
            <self>.puts("after")
            -> bb#1

          bb#5
            return
            -> bb#1

          bb#7
            <self>.puts("bar")
            -> bb#2

          bb#1
      CFG
    end

    # begin
    # rescue
    # ensure
    # &&, ||, and, or
    # raise?

    private

    sig { params(code: String, compact: T::Boolean).returns(CFG::Cluster) }
    def parse(code, compact: true)
      node = Spoom.parse_ruby(code, file: "-")
      cfg = CFG.from_node(node)
      cfg.compact! if compact
      cfg
    end
  end
end
