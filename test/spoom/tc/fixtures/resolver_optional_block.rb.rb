# typed: true

module M
  class C
    # sig {params(x: String).returns(String)}
    def self.id(x)
      x
    end
  end
end

class Test
  foo = T.let(
    lambda {|x: nil| 'hello, ' + x.to_s},
    T.proc.params(x: T.nilable(String)).returns(String)
  ) # error: Argument does not have asserted type `T.proc.params(arg0: T.nilable(String)).returns(String)`

  bar = lambda do |x = M::C.id('')|
    'hello, ' + x
  end

  qux = lambda do |x = puts('hello')|
    'input: ' + x.to_s
  end

  puts foo.call('')
  puts bar.call
  puts qux.call
end
