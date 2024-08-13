# typed: true
# frozen_string_literal: true

require "spoom"

unless ARGV.size == 1
  puts "Usage: ruby tc.rb <file>"
  exit 1
end

path = ARGV[0]

files = if File.file?(path)
  [path]
elsif File.directory?(path)
  Dir.glob("#{path}/**/*.{rb,rbi}")
else
  Dir.glob(path)
end

model = Spoom::Model.new

# Payload
payload = <<~RBI
  module Kernel
    def require; end
  end

  class BasicObject
  end

  class Object < BasicObject
    include Kernel
  end

  class Module
    def extend; end
    def include; end
  end

  class Class < Module
    sig { returns(T.attached_class) }
    def new; end
  end
RBI
model_builder = Spoom::Model::Builder.new(model, "<payload>")
model_builder.visit(Spoom.parse_ruby(payload, file: "<payload>"))

parsed_files = files.map do |file|
  node = Spoom.parse_ruby(File.read(file), file: file)
  model_builder = Spoom::Model::Builder.new(model, file)
  model_builder.visit(node)
  [file, node]
rescue Spoom::ParseError => e
  puts "Error parsing #{file}: #{e.message}"
  nil
end.compact

model.finalize!

# ast = Spoom::AST.from_prism(node, file: "-")
# puts ast.inspect

# desugar = Spoom::Desugar.new
# desugar.visit(node)
# puts node.inspect

# puts node.inspect
# infer = Spoom::Infer.infer(node)
parsed_files.each do |file, node|
  puts "resolve #{file}"
  resolver = Spoom::Resolver.new(model, file)
  resolver.visit(node)
end

# cfg.show_dot

# Parse
# Model
# Infer
# Resolve

# x = 0 # Integer from assign
# x.to_s # String from call

# y = x.to_s # String from call

# y ->
#   x -> Integer
#     .to_s -> String

#     resolved send
#       node
#       recv_type
#       method

#     unresolved send
#       node
#       recv_type
#       method

#       validate
