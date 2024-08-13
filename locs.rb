# typed: true
# frozen_string_literal: true

require "spoom"

code = <<~RB
  class Foo
    def foo; end # error: Missing sig

    foo
  # ^^^ error: Method `foo` does not exist

    def bar(x, y); end
          # ^ error: Missing sig

    class Foo
      def foo; end
        # ^^^ error: Method `foo` does not exist

      def bar(x, y); end
               # ^ error: Method `bar` does not exist
    end
  end
RB

context = Spoom::Context.new(".")
path = "test_file.rb"
context.write!(path, code)

node = Spoom.parse_ruby(code, file: "-")

snippet = Spoom::Snippet.from_file(path)
snippet.commands.each do |command|
  puts command
  puts command.target_location.string

  target_node = Spoom::Parse::FindNodeAtLocation.find(node, command.target_location)

  case command.name
  when "node"
    puts target_node&.slice
  when "type"
    puts target_node&.slice
  when "error"
    puts target_node&.slice
  else
    raise "Unknown command: #{command.name}"
  end
end
