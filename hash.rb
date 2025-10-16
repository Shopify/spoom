# typed: true
# frozen_string_literal: true

require "spoom"

class KeyUse
  #: Prism::Location
  attr_reader :key_check, :key_access

  #: (Prism::Location, Prism::Location) -> void
  def initialize(key_check, key_access)
    @key_check = key_check
    @key_access = key_access
  end
end

class HashVisitor < Prism::Visitor
  #: Array[KeyUse]
  attr_reader :uses

  #: (String) -> void
  def initialize(file)
    super()
    @file = file
    @uses = [] #: Array[KeyUse]
    @scopes = [{}] #: Array[Hash[String, Prism::Location]]
  end

  # @override
  #: (Prism::DefNode) -> void
  def visit_def_node(node)
    @scopes << {}
    super
    @scopes.pop
  end

  # @override
  #: (Prism::CallNode) -> void
  def visit_call_node(node)
    case node.name
    when :key?
      var = node.arguments&.arguments&.first&.slice

      if var
        # puts "Check `#{var}` at #{@file}:#{node.location.start_line}:#{node.location.start_column}"
        T.must(@scopes.last)[var] = node.location
      end
    when :[], :[]=
      var = node.arguments&.arguments&.first&.slice

      if var && T.must(@scopes.last).key?(var)
        # puts "Access `#{var}` at #{@file}:#{node.location.start_line}:#{node.location.start_column}"
        @uses << KeyUse.new(T.must(T.must(@scopes.last)[var]), node.location)
      end
    end

    super
  end
end

if ARGV.empty?
  puts "Usage: ruby hash.rb <file>"
  exit 1
end

files = ARGV.map do |file|
  if File.directory?(file)
    Dir.glob(File.join(file, "**/*.rb"))
  else
    [file]
  end
end.flatten

files.each do |file|
  v = HashVisitor.new(file)
  result = Prism.parse_file(file)
  if result.success?
    v.visit(result.value)
  else
    puts "Error parsing #{file}: #{result.errors.map(&:message).join(", ")}"
  end

  v.uses.each do |use|
    puts "#{file}:#{use.key_check.start_line}:#{use.key_check.start_column} -> #{file}:#{use.key_access.start_line}:#{use.key_access.start_column}"
  end
end
