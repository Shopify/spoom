# typed: true
# frozen_string_literal: true

require "parallel"

module Spoom
  module Cli
    class Model < Thor
      extend T::Sig
      include Helper

      class_option :exclude, type: :array, default: ["vendor/**"], desc: "Exclude directories"
      class_option :extensions, type: :array, default: [".rb"], desc: "Only include files with these extensions"

      desc "find FULL_NAME", "Find an entity in the model"
      def find(full_name)
        model = self.model
        scopes = find_scope(model, full_name)

        printer = Spoom::Model::Printer.new
        printer.visit_all(scopes)
        puts printer.out
      end

      desc "ancestors FULL_NAME", "Find ancestors of an entity"
      def ancestors(full_name)
        model = self.model
        find_scope(model, full_name)

        types = model.ancestors_of(full_name)

        if types.empty?
          puts "No ancestors found for #{blue(full_name)}"
          exit(0)
        end

        puts types
      end

      desc "descendants FULL_NAME", "Find descendants of an entity"
      def descendants(full_name)
        model = self.model
        find_scope(model, full_name)

        types = model.descendants_of(full_name)

        if types.empty?
          puts "No descendants found for #{blue(full_name)}"
          exit(0)
        end

        puts types
      end

      desc "graph [FOCUS]", "Generate a graph of the model"
      def graph(focus = nil)
        model = self.model
        printer = Spoom::Model::GraphPrinter.new(model)

        scopes = model.descendants_of("T::Props")
        scopes.each do |scope|
          next unless scope.location.file =~ /components\/payment_processing/
          next if scope.descendant_of?("PaymentsPartners::ValueObject")
          printer.visit(scope)
        end

        # if focus
        #   scope = find_scope(model, focus).first
        #   printer.visit(scope)
        #   printer.visit_all(model.ancestors_of(scope.full_name))
        #   printer.visit_all(model.descendants_of(scope.full_name))
        # else
        #   model.scopes.each do |_full_name, scopes|
        #     printer.visit(scopes.first)
        #   end
        # end

        context = Context.new(".")
        context.write!("graph.dot", printer.graph)
        puts context.exec("dot -Tpng graph.dot -o graph.png")
        # context.remove!("graph.dot")
        context.exec("open -F graph.png")
      end

      no_commands do
        def files
          collector = FileCollector.new(
            exclude_patterns: options[:exclude],
            allow_extensions: options[:extensions],
          )
          collector.visit_path(exec_path)
          collector.files
        end

        def model
          models = Parallel.map(files, in_processes: 10) do |file|
            Spoom::Model.from_file(file)
          end

          model = Spoom::Model.merge(models)
          model.resolve_ancestors!
          model
        end

        def find_scope(model, full_name)
          scopes = model.scopes[full_name]

          unless scopes&.any?
            error("Can't find #{yellow(full_name)}")
            exit(1)
          end

          scopes
        end
      end
    end
  end
end
