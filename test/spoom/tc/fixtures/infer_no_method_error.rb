foo # error: Method `foo` does not exist on `Object`

def bar # node: Prism::DefNode
  baz
# ^^^ error: Method `baz` does not exist on `Object`
end

[1, 2, 3]
  # ^ type: Integer
