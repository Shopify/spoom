# typed: true
# frozen_string_literal: true

def bar; end

def foo
  bar
end

y = 42

x = if foo?
  foo
  puts y
end
