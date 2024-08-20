puts "before"
for i in foo
  puts "foo"
  break if bar?
  puts "bar"
end
puts "after"
