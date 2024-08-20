puts "before"
until foo?
  puts "foo"
  break if bar?
  puts "bar"
end
puts "after"
