# typed: true
# frozen_string_literal: true

require "spoom"

code = <<~RUBY
  # foo = 1
  # if foo
  #   foo_if
  # end
  # bar

  # if foo
  #   foo_if
  # else
  #   foo_else
  # end

  1
  if foo
    2
    if bar
      3
    else
      4
    end
    5
  end
  6
RUBY

node = Spoom.parse_ruby(code, file: "-")
cfg = Spoom::CFG.from_node(node)
cfg.show_dot
