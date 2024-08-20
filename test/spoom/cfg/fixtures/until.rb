puts "before"
until foo?
  puts "foo"

  puts "bar" until bar?
end
puts "after"
