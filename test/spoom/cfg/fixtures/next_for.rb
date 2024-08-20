puts "before"
for i in foo
  puts "foo"
  next if bar?
  puts "bar"
end
puts "after"
