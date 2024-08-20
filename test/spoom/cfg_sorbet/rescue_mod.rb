# typed: true
class TestRescue
  def rescue_loop()
    ex = T.let(nil, T.nilable(StandardError))

    loop do
      ex = nil
      begin
        meth
      rescue => ex
      end
    end
  end

  def parse_ruby_bug_12686()
    take_arg (bar rescue nil)
  end

  def parse_rescue_mod()
    meth rescue bar
  end

  def parse_rescue_mod_op_assign()
    foo += meth rescue bar # error: Method `+` does not exist on `NilClass`
  end

  def parse_ruby_bug_12402()
    foo = raise(bar) rescue nil
  end

  def parse_ruby_bug_12402_1()
    foo += raise(bar) rescue nil # error: Method `+` does not exist on `NilClass`
  end

  def parse_ruby_bug_12402_2()
    foo[0] += raise(bar) rescue nil
  end
end
