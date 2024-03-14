require "spoom"

refs = T.let({}, T::Hash[String, T::Set[String]])

lines = File.read("out.files").lines
lines.each do |line|
  from, to = line.split(" -> ")

  from = from.split("/").first
  to = to.split("/").first

  next if from == to

  (refs[from] ||= Set.new) << to
end

json = []
refs.each do |from, tos|
  json << { name: "components.#{from}", imports: tos.map { |t| "components.#{t}"}.to_a }
end
puts JSON.pretty_generate(json)

dot = String.new
dot << "strict graph G {\n"
refs.each do |from, tos|
  tos.each do |to|
    dot << "\"#{from}\" -- \"#{to}\""
  end
end
dot << "}\n"

context = Spoom::Context.new(".")
context.write!("graph.dot", dot)

format = "png"
res = context.exec("dot -T#{format} graph.dot -o graph.#{format}")
raise "Error: #{res.err}" unless res.status

context.exec("open -W -F graph.#{format}")
context.remove!("graph.dot")
