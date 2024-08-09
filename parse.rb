# typed: true
# frozen_string_literal: true

require "prism"

class MyVisitor < Prism::Visitor
  attr_reader :counter

  def initialize
    @counter = 0
  end

  def visit_class_node(node)
    # puts "class #{node.name}"
    super
    @counter += 1
  end
end

v = MyVisitor.new

path = ARGV[0]
Dir.glob(path).each do |file|
  # puts "Parsing #{file}"
  res = Prism.parse_file(file)
  v.visit(res.value)
end

puts v.counter
