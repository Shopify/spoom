puts "before"
until foo?
  puts "foo"
  next if bar?
  puts "bar"
end
puts "after"
