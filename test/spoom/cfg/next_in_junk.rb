# typed: true
def foo
  next 5 # error: No `do` block around `next`
end
