# typed: true
# frozen_string_literal: true

begin
  puts "inside"
  if foo?
    return
    puts "dead"
  else
    return
    puts "dead"
  end

  puts "dead"
rescue
  puts "rescue"
  return
  puts "dead"
end

puts "after"
