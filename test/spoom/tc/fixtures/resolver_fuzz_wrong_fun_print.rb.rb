# typed: false
sig do # error: Malformed `sig`: No return type specified. Specify one with .returns()
  a&.o[]
# ^^^^^^ error: invalid in this context
end
def foo
end
