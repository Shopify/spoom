# typed: true
class Main
    extend T::Sig

    sig {returns(Junk)} # error: Unable to resolve constant
    def foo
        Junk.new # error: Unable to resolve constant
    end
end
puts Main.new.foo
