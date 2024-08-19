# typed: true
# frozen_string_literal: true

puts "before"
foo do |x|
  if foo?
    puts "will return"
    return x
    puts "dead"
  end
  puts "after return"
end
puts "after"
