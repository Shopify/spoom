# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class CFGTest < Minitest::Test
    extend T::Sig

    def test_empty
      cluster = parse("")
      assert_equal(1, cluster.cfgs.size)

      cfg = T.must(cluster.cfgs.first)
      assert_equal(1, cfg.blocks.size)

      block = T.must(cfg.blocks.first)
      assert_equal("0", block.name)
    end

    def test_top_level_instructions
      cluster = parse(<<~RB)
        puts "foo"
        puts "bar"
      RB
      assert_equal(1, cluster.cfgs.size)

      cfg = T.must(cluster.cfgs.first)
      assert_equal(1, cfg.blocks.size)

      block = T.must(cfg.blocks.first)
      assert_equal("0", block.name)

      assert_debug(<<~CFG, cluster)
        cfg: <main>

          bb#0
            puts "foo"
            puts "bar"
      CFG
    end

    def test_static_init_empty
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
      assert_equal(6, cluster.cfgs.size)

      assert_debug(<<~CFG, cluster)
        cfg: <main>

          bb#0
            class Foo

        cfg: Foo::<static-init>

          bb#0
            puts "foo"
            class Bar
            puts "/foo"

        cfg: Bar::<static-init>

          bb#0
            puts "bar"
            class << self
            puts "/bar"

        cfg: class << self::<static-init>

          bb#0
            puts "self"
            def foo
            private def bar; end
            puts "/self"

        cfg: foo

          bb#0

        cfg: bar

          bb#0
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            foo
            -> bb#1

          bb#1
            i
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            bar?
            -> bb#4
            -> bb#6

          bb#3
            puts "after"

          bb#4
            break
            -> bb#3

          bb#6
            puts "bar"
            -> bb#1
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            -> bb#1

          bb#1
            foo?
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            bar?
            -> bb#4
            -> bb#6

          bb#3
            puts "after"

          bb#4
            break
            -> bb#3

          bb#6
            puts "bar"
            -> bb#1
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            -> bb#1

          bb#1
            foo?
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            bar?
            -> bb#4
            -> bb#6

          bb#3
            puts "after"

          bb#4
            break
            -> bb#3

          bb#6
            puts "bar"
            -> bb#1
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            foo
            -> bb#2
            -> bb#3
            -> bb#1

          bb#2
            puts "one"
            -> bb#1

          bb#3
            puts "two"
            -> bb#1

          bb#1
            puts "after"
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            def foo
            puts "after"

        cfg: foo

          bb#0
            puts "foo"
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            foo
            -> bb#1

          bb#1
            i
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            -> bb#1

          bb#3
            puts "after"
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

      assert_debug(<<~CFG, cluster)
        cfg: <main>

          bb#0
            puts "before"
            foo?
            -> bb#1
            -> bb#3

          bb#1
            puts "foo"
            -> bb#3

          bb#3
            puts "after"
      CFG
    end

    def test_if_inline
      cluster = parse(<<~RB)
        puts "before"
        puts "foo" if foo?
        puts "after"
      RB

      assert_debug(<<~CFG, cluster)
        cfg: <main>

          bb#0
            puts "before"
            foo?
            -> bb#1
            -> bb#3

          bb#1
            puts "foo"
            -> bb#3

          bb#3
            puts "after"
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

      assert_debug(<<~CFG, cluster)
        cfg: <main>

          bb#0
            puts "before"
            foo?
            -> bb#1
            -> bb#2

          bb#1
            puts "foo"
            -> bb#3

          bb#2
            puts "bar"
            -> bb#3

          bb#3
            puts "after"
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            foo?
            -> bb#1
            -> bb#2

          bb#1
            puts "foo"
            -> bb#3

          bb#2
            bar?
            -> bb#4
            -> bb#3

          bb#3
            puts "after"

          bb#4
            puts "bar"
            -> bb#3
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            foo?
            -> bb#1
            -> bb#2

          bb#1
            puts "foo"
            -> bb#3

          bb#2
            bar?
            -> bb#4
            -> bb#5

          bb#3
            puts "after"

          bb#4
            puts "bar"
            -> bb#3

          bb#5
            puts "baz"
            -> bb#3
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            foo
            -> bb#1

          bb#1
            i
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            bar?
            -> bb#4
            -> bb#6

          bb#3
            puts "after"

          bb#4
            next
            -> bb#1

          bb#6
            puts "bar"
            -> bb#1
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            -> bb#1

          bb#1
            foo?
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            bar?
            -> bb#4
            -> bb#6

          bb#3
            puts "after"

          bb#4
            next
            -> bb#1

          bb#6
            puts "bar"
            -> bb#1
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            -> bb#1

          bb#1
            foo?
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            bar?
            -> bb#4
            -> bb#6

          bb#3
            puts "after"

          bb#4
            next
            -> bb#1

          bb#6
            puts "bar"
            -> bb#1
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            foo?
            -> bb#1
            -> bb#3

          bb#1
            puts "foo"
            -> bb#3

          bb#3
            puts "after"
      CFG
    end

    def test_unless_inline
      cluster = parse(<<~RB)
        puts "before"
        puts "foo" unless foo?
        puts "after"
      RB

      assert_debug(<<~CFG, cluster)
        cfg: <main>

          bb#0
            puts "before"
            foo?
            -> bb#1
            -> bb#3

          bb#1
            puts "foo"
            -> bb#3

          bb#3
            puts "after"
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

      assert_debug(<<~CFG, cluster)
        cfg: <main>

          bb#0
            puts "before"
            foo?
            -> bb#1
            -> bb#2

          bb#1
            puts "foo"
            -> bb#3

          bb#2
            puts "bar"
            -> bb#3

          bb#3
            puts "after"
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            -> bb#1

          bb#1
            foo?
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            -> bb#4

          bb#3
            puts "after"

          bb#4
            bar?
            -> bb#5
            -> bb#1

          bb#5
            puts "bar"
            -> bb#4
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

      assert_debug(<<~CFG, cluster.compact!)
        cfg: <main>

          bb#0
            puts "before"
            -> bb#1

          bb#1
            foo?
            -> bb#2
            -> bb#3

          bb#2
            puts "foo"
            -> bb#4

          bb#3
            puts "after"

          bb#4
            bar?
            -> bb#5
            -> bb#1

          bb#5
            puts "bar"
            -> bb#4
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

      assert_debug(<<~CFG, cluster)
        cfg: <main>

          bb#0
            def foo

        cfg: foo

          bb#0
            puts "before"
            yield
            puts "after"
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
        puts "after all"
      RB

      cluster.compact!.show_dot
      assert_debug(<<~CFG, cluster.compact!)
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

      cluster.compact!.show_dot
      assert_debug(<<~CFG, cluster.compact!)
      CFG
    end

    def test_return_if
      cluster = parse(<<~RB)
        puts "before"
        return if bar?
        puts "after"
      RB

      # cluster.compact!.show_dot
      assert_debug(<<~CFG, cluster.compact!)
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

      # cluster.compact!.show_dot
      assert_debug(<<~CFG, cluster.compact!)
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

      # cluster.compact!.show_dot
      assert_debug(<<~CFG, cluster.compact!)
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

      cluster.compact!.show_dot
      assert_debug(<<~CFG, cluster.compact!)
      CFG
    end

    # def test_return_args
    #   cfg = parse(<<~RB)
    #     0
    #     def foo
    #       1
    #       return 3, 4 if true
    #       5
    #     end
    #     2
    #   RB

    #   puts cfg.debug
    #   cfg.show_dot

    #   assert_equal(<<~CFG, cfg.debug)
    #     0
    #       -> 1
    #       -> 2
    #     1
    #     2
    #       -> 3
    #   CFG
    # end

    # block / do .. end / {}
    # begin
    # raise
    # rescue
    # ensure
    # &&, ||, and, or

    private

    sig { params(expected: String, cluster: CFG::Cluster).void }
    def assert_debug(expected, cluster)
      actual = cluster.inspect
      return if expected == actual

      puts "Actual:"
      puts actual
      puts "Diff:"
      $stderr.puts diff(expected, actual)
      raise
    end

    sig { params(code: String).returns(CFG::Cluster) }
    def parse(code)
      node = Spoom.parse_ruby(code, file: "-")
      CFG.from_node(node)
    end
  end
end
