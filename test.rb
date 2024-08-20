# typed: true
# frozen_string_literal: true

begin
  x = 1
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
  puts x
  puts "rescue"
  return
  puts "dead"
end
