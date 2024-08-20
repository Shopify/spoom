puts "before"
def foo
  puts "before"
  return
  puts "dead"
end

return
puts "dead2"
