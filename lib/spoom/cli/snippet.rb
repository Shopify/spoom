# typed: true
# frozen_string_literal: true

require_relative "../deadcode"

module Spoom
  module Cli
    class Snippet < Thor
      extend T::Sig
      include Helper

      default_task :snippet

      desc "snippet PATH", "Render snippet"
      def snippet(path)
        content = File.read(path)
        snippet = Spoom::Snippet.from_string(content, file: path)

        node = Spoom.parse_ruby(content, file: path)

        model = Spoom::Model.new
        model_builder = Spoom::Model::Builder.new(model, path)
        model_builder.visit(node)
        model.finalize!

        # resolver = Spoom::Resolver.new(model, path)
        # resolver.visit(node)
        # node_types = resolver.node_types

        puts content

        puts "Commands:"
        snippet.commands.each do |command|
          target_node = node_at_location(node, command.target_location)

          case command.name
          when "type"
            raise "No target node found" unless target_node

            puts command.target_location.string
            # puts node_types[target_node]
          when "typed", "frozen_string_literal"
          else
            puts "Unknown command: #{command.name}"
          end
        end
      end

      private

      sig { params(node: Prism::Node, target_location: Spoom::Location).returns(T.nilable(Prism::Node)) }
      def node_at_location(node, target_location)
        queue = [node]

        until queue.empty?
          current = T.must(queue.shift)
          current_location = Location.from_prism(target_location.file, current.location)

          return current if current_location == target_location
          next unless current_location.include?(target_location)

          current.child_nodes.each do |child|
            next unless child

            queue << child
          end
        end
      end
    end
  end
end
