begin
rescue MyException.new.class => e
  puts e
end
