# typed: true
# frozen_string_literal: true

def foo
  puts "before"
  return if bar?

  puts "after"
end
