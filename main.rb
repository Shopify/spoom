# typed: true
# frozen_string_literal: true

require "spoom"
require "parallel"

# model = Model.new
# files = Dir.glob("test.rb")
# files = Dir.glob("../shopify/**/*.rb")
files = Dir.glob("lib/**/*.rb")
# files = Dir.glob("lib/spoom/coverage/report.rb")
warn "Files: #{files.size}"
# files.each do |file|
#   source = File.read(file)
#   indexer = Model::Indexer.new(model, file, source)
#   tree = SyntaxTree.parse(source)
#   indexer.visit(tree)
# end

models = Parallel.map(files, in_processes: 10) do |file|
  model = Spoom::Model.new
  source = File.read(file)
  indexer = Spoom::Model::Builder.new(model, file, source)
  tree = SyntaxTree.parse(source)
  indexer.visit(tree)
  model
end

model = Spoom::Model.merge(models)
warn "Classes: #{model.classes.keys.size}"
warn "Modules: #{model.modules.keys.size}"
warn "Total: #{model.classes.keys.size + model.modules.keys.size}"
model.resolve_ancestors!

# model.classes.keys.sort.each do |full_name|
#   T.must(model.classes[full_name]).each do |klass|
#     puts klass
#     klass.includes.each do |mod|
#       puts "  include #{mod.full_name}"
#     end
#     klass.attrs.each do |attr|
#       puts "  #{attr}"
#     end
#     # klass.defs.each do |defn|
#     #   puts "  #{defn}"
#     # end
#   end
# end

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

# model.structs.each do |klass|
  # klass.props.each do |prop|
  #   puts "  #{prop}"
  # end
  # klass.defs.each do |defn|
  #   puts "  #{defn}"
  # end
# end

printer = Spoom::Model::Printer.new
printer.printl("# typed: ignore")
printer.visit(model)
puts printer.out

# puts "T::Structs"
# model.subclasses_of("T::Struct").each do |klass|
#   puts klass
# end

# model.subclasses_of("C1").each do |scope|
#   puts scope
# end

# model.descendants_of("T::Props").each do |scope|
#   puts scope
# end

# TODO: unify class defs into locs?
# TODO: unify prop/attr defs into props?
# TODO: search by ref?
# TODO: linearize model
# TODO: ancestors, descendants, parents, children

# Categorize
#  Pure ValueObject
#  ValueObject
#  Pure Struct
#  Struct
#
#  Other behavior
#  Serialization?
#  Inehrited objects => used for the build DSL

# Find the inherited T::Props
# Are Structs passed around? constructor, methods, attributs?
# Prop nesting, a prop containing a prop?
# Default values?

# Write report
#  Explain problem
#  Explain audit strategy
#  Count structs
#  Categorize
#  Observations
#  Recommendations
