# typed: true
# frozen_string_literal: true

begin
rescue MyException.new.class => e
  puts e
end
