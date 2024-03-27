# typed: true
# frozen_string_literal: true

require "spoom"
require "parallel"

extend T::Sig

private def resolve_enum_name(model, name, context)
  enum_scope = model.scopes[name]&.first
  enum_scope ||= model.resolve_name(name, context)

  enum_scope
end

sig { params(files: T::Array[String]).returns(Spoom::Model) }
def build_model(files)
  models = Parallel.map(files, in_processes: 10) do |file|
    Spoom::Model.from_file(file)
  end

  model = Spoom::Model.merge(models)
  model.resolve_ancestors!
  model
end

unless ARGV.size == 1
  warn "Usage: ruby main.rb <glob>"
  exit 1
end

# Build the model

files = Dir.glob(ARGV[0])
warn "Files: #{files.size}"
model = build_model(files)
warn "Classes: #{model.classes.keys.size}"
warn "Modules: #{model.modules.keys.size}"
warn "Total: #{model.classes.keys.size + model.modules.keys.size}"

# T::Enum Audit

enums = model.subclasses_of("T::Enum")
warn "Enums: #{enums.size}"

warn "-----\n\n"

# List all folders in a project
components = Dir.children("../../shopify/shopify/components").map { |c| c.split("/").last }

# Location of T::Enums
#
# ~~~
# components_to_enums = {}
# enums.each do |enum|
#   component = enum.location.file.split("/")[5]
#   (components_to_enums[component] ||= []) << enum
# end

# components.sort.each do |component|
#   e = components_to_enums[component] || []
#   warn "#{component}: #{e.uniq.size}"
# end
# ~~~

# Number of values in T::Enums
#
# ~~~
# values_to_enums = {}
# enums.each do |enum|
#   (values_to_enums[enum.enum_values.size] ||= []) << enum
# end

# values_to_enums.sort_by { |k, _v| k }.each do |k, v|
#   warn "#{k}: #{v.uniq.size}"
# end
# ~~~

# Most often defined methods in T::Enums:
#
# ~~~
# methods_to_enums = {}
# enums_to_methods = {}

# enums.each do |enum|
#   enum.defs.each do |defn|
#     (methods_to_enums[defn.name] ||= []) << enum
#     (enums_to_methods[enum.full_name] ||= []) << defn
#   end
# end

# warn "Most often defined methods in T::Enums:"
# methods_to_enums.each do |method, enums|
#   warn "- #{method}: #{enums.uniq.size}"
# end

# ~~~

# Most often included modules in T::Enum
#
# ~~~
# includes = {}
# enums.each do |enum|
#   enum.includes.each do |inc|
#     (includes[inc.full_name] ||= []) << enum
#   end
# end

# includes.sort_by { |_, v| -v.size }.each do |inc, enums|
#   warn "#{inc}: #{enums.uniq.size}"
# end

# ~~~

# Case statements with T::Enum
#
# ~~~

# cases_to_enums = {}

# model.cases.each do |c|
#   c.conditions.each do |cond|
#     cond = T.must(cond.split(", ").first)
#     scope = model.scopes[cond]&.first

#     unless scope
#       scope = model.resolve_name(cond, c.scope)
#     end

#     next unless scope

#     if scope.descendant_of?("T::Enum")
#       cases_to_enums[c] = scope
#       next
#     end
#   end
# end

# warn "Number of cases with T::Enum: #{cases_to_enums.size}"

# warn "Case with largest number of conditions:"
# cases_to_enums.sort_by { |k, _v| -k.conditions.size }.first(5).each do |k, _v|
#   puts "- #{k.conditions.size}: #{k.location}"
# end
# ~~~

# Calls to serialize and deserialize:
# ~~~
# enums_to_serialize_calls = {}
# enums_to_deserialize_calls = {}

# model.scopes.each do |_name, objs|
#   objs.each do |scope|
#     scope.calls_to_serialize.each do |c|
#       enum_scope = resolve_enum_name(model, c.recv_name, scope)
#       (enums_to_serialize_calls[enum_scope] ||= []) << c if enum_scope
#     end

#     scope.calls_to_deserialize.each do |c|
#       enum_scope = resolve_enum_name(model, c.recv_name, scope)
#       (enums_to_deserialize_calls[enum_scope] ||= []) << c if enum_scope
#     end
#   end
# end

# warn "Enums with most calls to serialize:"
# enums_to_serialize_calls.sort_by { |k, _v| -k.enum_values.size }.first(5).each do |k, v|
#   warn "- #{k.full_name}: #{v.first.location}"
# end
# ~~~
