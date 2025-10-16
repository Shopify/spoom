# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Metrics
      class << self
        #: (Array[String]) -> Spoom::Counters
        def collect_code_metrics(files)
          counters = Counters.new

          files.each do |file|
            counters.increment("files")

            content = File.read(file)
            node, _ = Spoom.parse_ruby(content, file: file)
            visitor = CodeMetricsVisitor.new(counters)
            visitor.visit(node)
          end

          counters
        end
      end

      # Collects metrics about how Sorbet is used in the codebase.
      #
      # This approach is different from the metrics file we get directly from Sorbet.
      #
      # This visitor actually visits the codebase and collects metrics about the amount of signatures, `T.` calls,
      # and other metrics. It also knows about RBS comments.
      #
      # On the other hand, the metrics file is a snapshot of the metrics at type checking time and knows about
      # is calls are typed, how many assertions are done, etc.
      class CodeMetricsVisitor < Spoom::Visitor
        include RBS::ExtractRBSComments

        #: (Spoom::Counters) -> void
        def initialize(counters)
          super()

          @counters = counters

          @last_sigs = [] #: Array[Prism::CallNode]
          @type_params = [] #: Array[Prism::CallNode]
        end

        # @override
        #: (Prism::Node?) -> void
        def visit(node)
          return if node.nil?

          node.location.trailing_comments.each do |comment|
            text = comment.slice.strip
            next unless text.start_with?("#:")

            @counters.increment("rbs_assertions")

            case text
            when /^#: as !nil/
              @counters.increment("rbs_must")
            when /^#: as untyped/
              @counters.increment("rbs_unsafe")
            when /^#: as/
              @counters.increment("rbs_cast")
            when /^#:/
              @counters.increment("rbs_let")
            end
          end

          super
        end

        # @override
        #: (Prism::ClassNode) -> void
        def visit_class_node(node)
          visit_scope(node) do
            super
          end
        end

        # @override
        #: (Prism::ModuleNode) -> void
        def visit_module_node(node)
          visit_scope(node) do
            super
          end
        end

        # @override
        #: (Prism::SingletonClassNode) -> void
        def visit_singleton_class_node(node)
          visit_scope(node) do
            super
          end
        end

        # @override
        #: (Prism::DefNode) -> void
        def visit_def_node(node)
          unless node.name.to_s.start_with?("test_")
            @counters.increment("methods")

            rbs_sigs = node_rbs_comments(node).signatures
            srb_sigs = collect_last_srb_sigs

            if rbs_sigs.any?
              @counters.increment("methods_with_rbs_sig")
            end

            if srb_sigs.any?
              @counters.increment("methods_with_srb_sig")
            end

            if rbs_sigs.empty? && srb_sigs.empty?
              @counters.increment("methods_without_sig")
            end
          end

          super
        end

        # @override
        #: (Prism::CallNode) -> void
        def visit_call_node(node)
          @counters.increment("calls")

          case node.name
          when :attr_accessor, :attr_reader, :attr_writer
            visit_attr_accessor(node)
            return
          when :sig
            visit_sig(node)
            return
          when :type_member, :type_template
            visit_type_member(node)
            return
          end

          case node.receiver&.slice
          when /^(::)?T$/
            @counters.increment("T_calls")
            @counters.increment("T.#{node.name}")
          end

          super
        end

        private

        #: (Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode) { -> void } -> void
        def visit_scope(node, &block)
          key = node_key(node)
          @counters.increment(key)
          @counters.increment("#{key}_with_rbs_type_params") if node_rbs_comments(node).signatures.any?

          old_type_params = @type_params
          @type_params = []

          yield

          @counters.increment("#{key}_with_srb_type_params") if @type_params.any?

          @type_params = old_type_params
        end

        #: (Prism::CallNode) -> void
        def visit_attr_accessor(node)
          @counters.increment("accessors")

          rbs_sigs = node_rbs_comments(node).signatures
          srb_sigs = collect_last_srb_sigs

          if rbs_sigs.any?
            @counters.increment("accessors_with_rbs_sig")
          end

          if srb_sigs.any?
            @counters.increment("accessors_with_srb_sig")
          end

          if rbs_sigs.empty? && srb_sigs.empty?
            @counters.increment("accessors_without_sig")
          end
        end

        #: (Prism::CallNode) -> void
        def visit_sig(node)
          @last_sigs << node
          @counters.increment("srb_sigs")

          if node.slice =~ /abstract/
            @counters.increment("srb_sigs_abstract")
          end
        end

        #: (Prism::CallNode) -> void
        def visit_type_member(node)
          key = case node.name
          when :type_member
            "type_members"
          when :type_template
            "type_templates"
          else
            return
          end

          @counters.increment(key)

          @type_params << node
        end

        #: -> Array[Prism::CallNode]
        def collect_last_srb_sigs
          sigs = @last_sigs.dup
          @last_sigs.clear
          sigs
        end

        #: (Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode) -> String
        def node_key(node)
          case node
          when Prism::ClassNode
            "classes"
          when Prism::ModuleNode
            "modules"
          when Prism::SingletonClassNode
            "singleton_classes"
          end
        end
      end
    end
  end
end
