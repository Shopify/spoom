# typed: true
# frozen_string_literal: true

require "spoom"
require "parallel"

unless ARGV.size == 1
  warn "Usage: ruby main.rb <glob>"
  exit 1
end

files = Dir.glob(ARGV[0])
warn "Files: #{files.size}"

models = Parallel.map(files, in_processes: 10) do |file|
  Spoom::Model.from_file(file)
end

model = Spoom::Model.merge(models)
warn "Classes: #{model.classes.keys.size}"
warn "Modules: #{model.modules.keys.size}"
warn "Total: #{model.classes.keys.size + model.modules.keys.size}"

model.resolve_ancestors!

# unresolved_count = 0
# model.scopes.keys.sort.each do |full_name|
#   T.must(model.scopes[full_name]).each do |scope|
#     next unless scope.is_a?(Model::Class)
#     next unless scope.superclass_name && scope.superclass.nil?

#     puts scope
#     unresolved_count += 1
#   end
# end
# puts "Unresolved: #{unresolved_count}"

# Print the whole model
# printer = Spoom::Model::Printer.new
# printer.printl("# typed: ignore")
# printer.visit(model)
# puts printer.out

structs = model.subclasses_of("T::Struct")
warn "Structs: #{structs.size}"

# Print code for structs
# printer = Spoom::Model::Printer.new
# printer.printl("# typed: ignore")
# structs.each do |struct|
#   printer.visit(struct)
# end
# puts printer.out

# structs.each do |struct|
#   puts "#{struct.full_name}\t#{struct.location.file}\t#{struct.props.select(&:read_only).size}\t#{struct.props.reject(&:read_only).size}"
# end

# groups = {
#   "all_consts" => 0,
#   "all_props" => 0,
#   "mixed" => 0,
# }
# structs.each do |struct|
#   if struct.props.all?(&:read_only)
#     groups["all_consts"] += 1
#   elsif struct.props.none?(&:read_only)
#     groups["all_props"] += 1
#   else
#     groups["mixed"] += 1
#   end
# end
# puts groups

# structs.each do |struct|
#   puts "#{struct.full_name}\t#{struct.location.file}\t#{struct.props.select(&:read_only).size}\t#{struct.props.reject(&:read_only).size}\t#{struct.defs.size}"
# end

# groups = {
#   "pure_struct" => 0,
#   "with_defs" => 0,
# }
# structs.each do |struct|
#   if struct.defs.empty?
#     groups["pure_struct"] += 1
#   else
#     groups["with_defs"] += 1
#   end
# end
# puts groups

# model.descendants_of("T::Props").each do |scope|
#   puts scope
# end

# methods = {}
# structs.each do |struct|
#   struct.defs.each do |defn|
#     (methods[defn.name] ||= []) << defn.name
#   end
# end
# methods.each do |name, defn|
#   puts "#{name}\t#{defn.size}"
# end

# structs.each do |struct|
#   if struct.defs.any? { |defn| defn.name == "initialize" }
#     puts "#{struct.full_name}\t#{struct.location.file}"
#   end
# end

# kinds = {
#   "const" => 0,
#   "const + default" => 0,
#   "prop" => 0,
#   "prop + default" => 0,
# }
# structs.each do |struct|
#   struct.props.each do |prop|
#     if prop.read_only && prop.has_default
#       kinds["const + default"] += 1
#     elsif prop.read_only
#       kinds["const"] += 1
#     elsif prop.has_default
#       kinds["prop + default"] += 1
#     else
#       kinds["prop"] += 1
#     end
#   end
# end

# kinds.each do |kind, count|
#   puts "#{kind}\t#{count}"
# end

# structs.each do |struct|
#   puts "#{struct.full_name}\t#{struct.location.file}\t#{struct.includes.size}"
# end

includes = {}
structs.each do |struct|
  struct.includes.each do |inc|
    (includes[inc.full_name] ||= []) << inc.full_name
  end
end
includes.each do |name, inc|
  puts "#{name}\t#{inc.size}"
end

# TODO: write tests for the model
# TODO: unify class defs into locs?
# TODO: unify prop/attr defs into props?
# TODO: search by ref? ref equality?
# TODO: linearize model
# TODO: ancestors, descendants, parents, children

# Find the inherited T::Props
#  Inehrited objects => used for the build DSL
#  Serialization?
#  Validation
#  InexactStruct
#  Abstract?
#  Implement interface?

# Are Structs passed around? constructor, methods, attributs?
# Prop nesting, a prop containing a prop?
