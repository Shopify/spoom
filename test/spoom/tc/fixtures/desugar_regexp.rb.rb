# typed: true
def foo
    /abc/
    Regexp.new('abc')

    /abc/i
    Regexp.new('abc', Regexp::IGNORECASE)

    /abc/nesuixm
    Regexp.new('abc', 0 | Regexp::IGNORECASE | Regexp::EXTENDED | Regexp::MULTILINE)

    a = "a"
    c = "c"
    /#{a}b#{c}/
    Regexp.new(a + 'b' + c)

    /abc/a # error: unknown regexp options: a
end
