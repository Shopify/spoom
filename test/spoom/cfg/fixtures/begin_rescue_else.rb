begin
  puts 1
  puts 2
rescue
  puts "rescue1"
rescue
  puts "rescue2"
else
  puts "else"
end

puts "after"
