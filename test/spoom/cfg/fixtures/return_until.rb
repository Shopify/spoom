puts "before"
until foo?
  puts "foo"
  return if bar?
  puts "bar"
end
puts "after"
