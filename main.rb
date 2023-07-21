# typed: true
# frozen_string_literal: true

require "spoom"
require "parallel"

extend T::Sig

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

# T::Struct audit

# Number of classes inheriting from T::Struct:
#
# ~~~
structs = model.subclasses_of("T::Struct")
puts "Structs: #{structs.size}"
# ~~~

# Location of classes inheriting from T::Struct:
#
# ~~~
# structs = model.subclasses_of("T::Struct")
# structs.each do |struct|
#   puts "#{struct.full_name}\t#{struct.location.file}"
# end
# ~~~

# Number of properties (const & prop) in classes inheriting from T::Struct:
#
# ~~~
# structs = model.subclasses_of("T::Struct")
# structs.each do |struct|
#   puts "#{struct.full_name}\t#{struct.location.file}\t#{struct.props.select(&:read_only).size}\t#{struct.props.reject(&:read_only).size}\t#{struct.defs.size}"
# end
# ~~~

# Group T::Structs by kind of properties used (all const vs. all prop vs. mixed)
#
# ~~~
# structs = model.subclasses_of("T::Struct")
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
# ~~~

# Group T::Structs by kind (only consts + props vs. using defs):
# ~~~
# structs = model.subclasses_of("T::Struct")
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
# ~~~

# T::Struct using defaults:
#
# ~~~
# structs = model.subclasses_of("T::Struct")
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
# puts kinds
# ~~~

# Most often defined methods in T::Structs:
#
# ~~~
# structs = model.subclasses_of("T::Struct")
# methods = {}
# structs.each do |struct|
#   struct.defs.each do |defn|
#     (methods[defn.name] ||= []) << defn.name
#   end
# end
# methods.each do |name, defn|
#   puts "#{name}\t#{defn.size}"
# end
# ~~~

# Most often included modules in T::Struct:
#
# ~~~
# structs = model.subclasses_of("T::Struct")
# includes = {}
# structs.each do |struct|
#   struct.includes.each do |inc|
#     (includes[inc.full_name] ||= []) << inc.full_name
#   end
# end
# includes.each do |name, inc|
#   puts "#{name}\t#{inc.size}"
# end
# ~~~

# Depth in inheritance tree of T::Structs:
#
# ~~~
# structs = model.subclasses_of("T::Struct")
# structs.each do |struct|
#   dit = model.depth_of_inheritance_tree(struct.full_name)
#   puts "#{struct.full_name}\t#{struct.location.file}\t#{dit}"
# end
# ~~~

# T::Props audit

# Number of classes/modules including from T::Props:
#
# ~~~
# tprops = model.children_of("T::Props")
# puts "T::Props (direct): #{tprops.size}"
# tprops = model.descendants_of("T::Props")
# puts "T::Props (trans): #{tprops.size}"
# ~~~

# Locations of classes/modules including from T::Props:
#
# ~~~
# tprops = model.descendants_of("T::Props")
# tprops.each do |tprop|
#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.child_of?("T::Props") ? "direct" : "transitive"}"
# end
# ~~~

# T::Props ancestors
#
# ~~~
# tprops = model.descendants_of("T::Props")
# tprops.each do |tprop|
#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.location.component}\t" \
#     "#{tprop.kind}\t" \
#     "#{model.depth_of_inheritance_tree(tprop.full_name)}\t" \
#     "#{tprop.is_a?(Spoom::Model::Class) ? tprop.superclass&.full_name : "N/A"}\t"
#     "#{tprop.includes.map(&:full_name).join(",")}"
# end
# ~~~

# Children of PaymentsPartners::ValueObject
#
# ~~~
# tprops = model.descendants_of("PaymentsPartners::ValueObject")
# tprops.each do |tprop|
#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.location.component}\t"
# end
# puts tprops.size
# ~~~

# T::Props usages of `const` and `prop`
#
# ~~~
# tprops = model.descendants_of("T::Props")
# tprops.each do |tprop|
#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.location.component}\t" \
#     "#{tprop.kind}\t" \
#     "#{tprop.child_of?("T::Props") ? "direct" : "transitive"}\t" \
#     "#{tprop.props.select(&:read_only).size}\t#{tprop.props.reject(&:read_only).size}\t#{tprop.defs.size}"
# end
# ~~~

# Most often defined methods in T::Props:
#
# ~~~
# tprops = model.descendants_of("T::Props")
# methods = {}
# tprops.each do |tprop|
#   tprop.defs.each do |defn|
#     (methods[defn.name] ||= []) << defn.name
#   end
# end
# methods.each do |name, defn|
#   puts "#{name}\t#{defn.size}"
# end
# ~~~

# Count of modules included in T::Props:
#
# ~~~
# tprops = model.descendants_of("T::Props")
# tprops.each do |tprop|
#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.location.component}\t#{tprop.includes.size}"
# end
# ~~~

# Most often included modules in T::Props:
#
# ~~~
# tprops = model.descendants_of("T::Props")
# includes = {}
# tprops.each do |tprop|
#   tprop.includes.each do |inc|
#     (includes[inc.full_name] ||= []) << inc.full_name
#   end
# end
# includes.each do |name, inc|
#   puts "#{name}\t#{inc.size}"
# end
# ~~~

# T::Props DIT:
#
# ~~~
# tprops = model.descendants_of("T::Props")
# tprops.each do |tprop|
#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.location.component}\t#{model.depth_of_inheritance_tree(tprop.full_name)}"
# end
# ~~~

# T::Props + T::Props::Constructor:
#
# ~~~
# tprops = model.descendants_of("T::Props")
# tprops.each do |tprop|
#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.location.component}\t#{tprop.includes.any? { |inc| inc.full_name == "T::Props::Constructor"}}\t#{tprop.defs.any? { |defn| defn.name == "initialize"}}"
# end
# ~~~

# T::Props + T::Struct:
#
# ~~~
# tprops = model.descendants_of("T::Props")
# tprops.each do |tprop|
#   next unless tprop.descendant_of?("T::Struct")

#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.location.component}"
# end
# ~~~

# T::Props::ValueObject:
#
# ~~~
tprops = model.descendants_of("T::Props::ValueObject")
puts "T::Props::ValueObject: #{tprops.size}"
# tprops.each do |tprop|
#   puts "#{tprop.full_name}\t#{tprop.location.file}\t#{tprop.location.component}"
# end
# ~~~
