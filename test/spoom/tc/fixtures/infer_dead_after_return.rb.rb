# typed: true

def dead_code
  x = nil
  return if !x

  x # error: unreachable
end
