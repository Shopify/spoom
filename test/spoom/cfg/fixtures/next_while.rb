puts "before"
while foo?
  puts "foo"
  next if bar?
  puts "bar"
end
puts "after"
