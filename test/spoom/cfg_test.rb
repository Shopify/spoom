# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class CFGTest < Minitest::Test
    extend T::Sig

    def test_empty
      cfg = parse("")

      blocks = cfg.blocks
      assert_equal(1, blocks.size)

      first = T.must(blocks.first)
      assert_same(first, cfg.root)
      assert_empty(first.instructions)
    end

    def test_single_block
      cfg = parse(<<~RB)
        foo
        bar
        baz
      RB

      blocks = cfg.blocks
      assert_equal(1, blocks.size)

      first = T.must(blocks.first)
      assert_same(first, cfg.root)
      assert_equal("0", first.name)
      assert_equal(["foo", "bar", "baz"], first.instructions.map(&:slice))
    end

    def test_break_for
      cfg = parse(<<~RB)
        0
        for i in []
          2
          break
          3
        end
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 1
          -> 3
        3
          -> 1
          -> 2
      CFG
    end

    def test_break_until
      cfg = parse(<<~RB)
        0
        until true
          2
          break
          3
        end
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 1
          -> 3
        3
          -> 1
          -> 2
      CFG
    end

    def test_case_when
      cfg = parse(<<~RB)
        0
        case foo
        when a
          2
        when b
          3
        else
          4
        end
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 2
        1
        2
          -> 1
          -> 3
          -> 4
        3
          -> 1
        4
          -> 1
      CFG
    end

    def test_def
      cfg = parse(<<~RB)
        0
        def foo
          1
        end
        2
      RB

      puts cfg.debug
      cfg.show_dot

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 3
      CFG
    end

    def test_for
      cfg = parse(<<~RB)
        0
        for i in []
          2
        end
        1
        for i in []
          4
          for i in []
            6
          end
          5
        end
        3
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
          -> 3
          -> 4
        2
          -> 1
          -> 2
        3
        4
          -> 5
          -> 6
        5
          -> 3
          -> 4
        6
          -> 5
          -> 6
      CFG
    end

    def test_if
      cfg = parse(<<~RB)
        0
        if foo
          2
        end
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 1
      CFG
    end

    def test_if_inline
      cfg = parse(<<~RB)
        0
        2 if foo
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 1
      CFG
    end

    def test_if_else
      cfg = parse(<<~RB)
        0
        if foo
          2
        else
          3
        end
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 2
          -> 3
        1
        2
          -> 1
        3
          -> 1
      CFG
    end

    def test_if_elsif
      cfg = parse(<<~RB)
        0
        if foo
          2
        # 3 (merge)
        elsif bar
          5
        end
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 2
          -> 3
        1
        2
          -> 1
        3
          -> 4
          -> 5
        4
          -> 1
        5
          -> 4
      CFG
    end

    def test_if_elsif_else
      cfg = parse(<<~RB)
        0
        if foo
          2
        # 3 (else)
        elsif bar
          5
        else
          6
        end
        # 4 (merge)
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 2
          -> 3
        1
        2
          -> 1
        3
          -> 5
          -> 6
        4
          -> 1
        5
          -> 4
        6
          -> 4
      CFG
    end

    def test_next_for
      cfg = parse(<<~RB)
        0
        for i in []
          2
          next
          3
        end
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 2
          -> 3
        3
          -> 1
          -> 2
      CFG
    end

    def test_next_until
      cfg = parse(<<~RB)
        0
        until true
          2
          next
          3
        end
        1
      RB

      puts cfg.debug
      cfg.show_dot

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 2
          -> 3
        3
          -> 1
          -> 2
      CFG
    end

    def test_unless
      cfg = parse(<<~RB)
        0
        unless true
          2
          4 unless true
          3
        end
        1
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 3
          -> 4
        3
          -> 1
        4
          -> 3
      CFG
    end

    def test_until
      cfg = parse(<<~RB)
        0
        until true
          2
        end
        1
        until true
          4
          until true
            6
          end
          5
        end
        3
      RB

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
          -> 3
          -> 4
        2
          -> 1
          -> 2
        3
        4
          -> 5
          -> 6
        5
          -> 3
          -> 4
        6
          -> 5
          -> 6
      CFG
    end

    def test_yield
      cfg = parse(<<~RB)
        0
        def foo
          1
          yield
          2
        end
        # 2 exit foo
        3
      RB

      puts cfg.debug
      cfg.show_dot

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
        1
      CFG
    end

    def test_return
      cfg = parse(<<~RB)
        0
        def foo
          1
          return
          3
        end
        2
      RB

      puts cfg.debug
      cfg.show_dot

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 3
      CFG
    end

    def test_return_args
      cfg = parse(<<~RB)
        0
        def foo
          1
          return 3, 4 if true
          5
        end
        2
      RB

      puts cfg.debug
      cfg.show_dot

      assert_equal(<<~CFG, cfg.debug)
        0
          -> 1
          -> 2
        1
        2
          -> 3
      CFG
    end

    # block / do .. end / {}
    # begin
    # raise
    # rescue
    # ensure
    # &&, ||, and, or

    private

    sig { params(code: String).returns(CFG) }
    def parse(code)
      CFG.from_node(Spoom.parse_ruby(code, file: "-"))
    end
  end
end
