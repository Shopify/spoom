class Foo
end

class Bar < Foo
end

class Baz < Bar
end

class Qux < Unknown
          # ^^^^^^^ error: Unable to resolve constant `Unknown`
end
