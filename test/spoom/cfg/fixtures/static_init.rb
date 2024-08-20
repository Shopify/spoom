class Foo
  puts "foo"
  class Bar
    puts "bar"
    class << self
      puts "self"
      def foo; end
      private def bar; end
      puts "/self"
    end
    puts "/bar"
  end
  puts "/foo"
end
