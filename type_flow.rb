# typed: true
# frozen_string_literal: true

require "prism"

unless ARGV.size == 1
  puts "Usage: ruby #{$PROGRAM_NAME} <file>"
  exit 1
end

path = ARGV[0]

files = if File.file?(path)
  [path]
elsif File.directory?(path)
  Dir.glob("#{path}/**/*.{rb}")
else
  Dir.glob(path)
end

class Visitor < Prism::Visitor
  attr_reader :counters

  def initialize
    super()

    @counters = Hash.new(0)
  end

  def visit_def_node(node)
    @current_scope = {}
    super
    @current_scope = nil
  end

  def visit_call_node(node)
    @counters[node.class.to_s] += 1

    recv = node.receiver
    if recv && @current_scope && @current_scope[recv.slice]
      @counters["inferable_call"] += 1
    else
      @counters["non_inferable_call"] += 1
    end

    super
  end

  def visit_local_variable_write_node(node)
    @counters[node.class.to_s] += 1
    super

    value = node.value
    case value
    when Prism::CallNode
      return unless value.receiver.is_a?(Prism::ConstantReadNode) || value.receiver.is_a?(Prism::ConstantPathNode)
      return unless value.name == :new

      @counters["#{value.class}.new"] += 1
      @current_scope[node.name.to_s] = true if @current_scope
    when Prism::StringNode,
         Prism::SymbolNode,
         Prism::IntegerNode,
         Prism::FloatNode,
         Prism::NilNode,
         Prism::TrueNode,
         Prism::FalseNode,
         Prism::ArrayNode,
         Prism::HashNode
      @counters[value.class.to_s] += 1
      @current_scope[node.name.to_s] = true if @current_scope
    end
  end
end

v = Visitor.new

files.each do |file|
  next if file =~ /test/

  res = Prism.parse_file(file)
  next if res.errors.any?

  v.visit(res.value)
end

def percent(value, total)
  return 0 if total.zero?

  (value.to_f / total * 100).round(2)
end

counters = v.counters

total_call = counters["Prism::CallNode"]
counters.delete("Prism::CallNode")
inferable_call = counters["inferable_call"]
counters.delete("inferable_call")
non_inferable_call = counters["non_inferable_call"]
counters.delete("non_inferable_call")

puts "Prism::CallNode: #{total_call}"
puts " * Inferable calls: #{inferable_call} (#{percent(inferable_call, total_call)}%)"
puts " * Non-inferable calls: #{non_inferable_call} (#{percent(non_inferable_call, total_call)}%)"

total_write = counters["Prism::LocalVariableWriteNode"]
counters.delete("Prism::LocalVariableWriteNode")

puts "\nPrism::LocalVariableWriteNode: #{total_write}"

puts "Inferable types on assign:"
counters.sort_by { |_k, v| -v }.each do |klass, count|
  percent = percent(count, total_write)
  puts " * #{klass}: #{count} (#{percent}%)"
end

total = counters.values.sum
puts "\n   Total: #{total} (#{percent(total, total_write)}%)"
