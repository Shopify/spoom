# typed: true
class TestNext
  extend T::Sig

  def _; end
  def done?; end

  def test_next
    while _.test { done? }
      puts
    end
  end

  sig {params(blk: T.proc.returns(String)).returns(String)}
  def yields(&blk)
    blk.call
  end

  def test_while_in_next
    yields do
      while _
        next 4 # no error: `next` binds to the while, not the block
      end

      "hi"
    end
  end
end
