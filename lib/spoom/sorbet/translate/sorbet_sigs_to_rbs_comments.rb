# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      # Converts all `sig` nodes to RBS comments in the given Ruby code.
      # It also handles type members and class annotations.
      class SorbetSigsToRBSComments < Translator
        #: (String, file: String, positional_names: bool) -> void
        def initialize(ruby_contents, file:, positional_names:)
          super(ruby_contents, file: file)

          @positional_names = positional_names #: bool
          @nesting = [] #: Array[Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode]
          @last_sigs = [] #: Array[[Prism::CallNode, RBI::Sig]]
        end

        # @override
        #: (Prism::ClassNode) -> void
        def visit_class_node(node)
          visit_scope(node) { super }
        end

        # @override
        #: (Prism::ModuleNode) -> void
        def visit_module_node(node)
          visit_scope(node) { super }
        end

        # @override
        #: (Prism::SingletonClassNode) -> void
        def visit_singleton_class_node(node)
          visit_scope(node) { super }
        end

        # @override
        #: (Prism::DefNode) -> void
        def visit_def_node(node)
          return if @last_sigs.empty?
          return if @last_sigs.any? { |_, sig| sig.is_abstract }

          apply_member_annotations(@last_sigs)

          # Build the RBI::Method node so we can print the method signature as RBS.
          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Method

          @last_sigs.each do |node, sig|
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out, indent: node.location.start_column, positional_names: @positional_names)
            p.print("#: ")
            p.send(:print_method_sig, rbi_node, sig)
            p.print("\n")
            @rewriter << Source::Replace.new(node.location.start_offset, node.location.end_offset, out.string)
          end

          @last_sigs.clear
        end

        # @override
        #: (Prism::CallNode) -> void
        def visit_call_node(node)
          case node.message
          when "sig"
            visit_sig(node)
          when "attr_reader", "attr_writer", "attr_accessor"
            visit_attr(node)
          when "extend"
            visit_extend(node)
          when "abstract!", "interface!", "sealed!", "final!", "requires_ancestor"
            visit_class_annotation(node)
          else
            super
          end
        end

        private

        #: (Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode) { -> void } -> void
        def visit_scope(node, &block)
          @nesting << node

          yield

          @nesting.pop
        end

        #: (Prism::CallNode) -> void
        def visit_sig(node)
          return unless sorbet_sig?(node)

          builder = RBI::Parser::SigBuilder.new(@ruby_contents, file: @file)
          builder.current.loc = node.location
          builder.visit_call_node(node)
          builder.current.comments = []

          @last_sigs << [node, builder.current]
        end

        #: (Prism::CallNode) -> void
        def visit_attr(node)
          unless node.message == "attr_reader" || node.message == "attr_writer" || node.message == "attr_accessor"
            raise Error, "Expected attr_reader, attr_writer, or attr_accessor"
          end

          return if @last_sigs.empty?
          return if @last_sigs.any? { |_, sig| sig.is_abstract }

          apply_member_annotations(@last_sigs)

          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Attr

          @last_sigs.each do |node, sig|
            out = StringIO.new
            p = RBI::RBSPrinter.new(out: out, indent: node.location.start_column, positional_names: @positional_names)
            p.print("#: ")
            p.print_attr_sig(rbi_node, sig)
            p.print("\n")
            @rewriter << Source::Replace.new(node.location.start_offset, node.location.end_offset, out.string)
          end

          @last_sigs.clear
        end

        #: (Prism::CallNode node) -> void
        def visit_extend(node)
          raise Error, "Expected extend" unless node.message == "extend"

          return unless node.receiver.nil? || node.receiver.is_a?(Prism::SelfNode)
          return unless node.arguments&.arguments&.size == 1

          arg = node.arguments&.arguments&.first
          return unless arg.is_a?(Prism::ConstantPathNode)
          return unless arg.slice.match?(/^(::)?T::Helpers$/) || arg.slice.match?(/^(::)?T::Generic$/)

          from = adjust_to_line_start(node.location.start_offset)
          to = adjust_to_line_end(node.location.end_offset)

          if to + 1 < @ruby_bytes.size && @ruby_bytes[to + 1] == "\n".ord
            to += 1
          end

          @rewriter << Source::Delete.new(from, to)
        end

        #: (Prism::CallNode node) -> void
        def visit_class_annotation(node)
          unless node.message == "abstract!" || node.message == "interface!" || node.message == "sealed!" ||
              node.message == "final!" || node.message == "requires_ancestor"
            raise Error, "Expected abstract!, interface!, sealed!, final!, or requires_ancestor"
          end

          return unless node.receiver.nil? || node.receiver.is_a?(Prism::SelfNode)
          return unless node.arguments.nil?

          klass = @nesting.last #: as Prism::Node
          indent = " " * klass.location.start_column

          case node.message
          when "abstract!"
            @rewriter << Source::Insert.new(klass.location.start_offset, "# @abstract\n#{indent}")
          when "interface!"
            @rewriter << Source::Insert.new(klass.location.start_offset, "# @interface\n#{indent}")
          when "sealed!"
            @rewriter << Source::Insert.new(klass.location.start_offset, "# @sealed\n#{indent}")
          when "final!"
            @rewriter << Source::Insert.new(klass.location.start_offset, "# @final\n#{indent}")
          when "requires_ancestor"
            block = node.block
            return unless block.is_a?(Prism::BlockNode)

            body = block.body
            return unless body.is_a?(Prism::StatementsNode)
            return unless body.body.size == 1

            arg = body.body.first #: as Prism::Node
            srb_type = RBI::Type.parse_node(arg)
            @rewriter << Source::Insert.new(klass.location.start_offset, "# @requires_ancestor: #{srb_type.rbs_string}\n#{indent}")
          end

          from = adjust_to_line_start(node.location.start_offset)
          to = adjust_to_line_end(node.location.end_offset)

          if to + 1 < @ruby_bytes.size && @ruby_bytes[to + 1] == "\n".ord
            to += 1
          end

          @rewriter << Source::Delete.new(from, to)
        end

        #: (Array[[Prism::CallNode, RBI::Sig]]) -> void
        def apply_member_annotations(sigs)
          return if sigs.empty?

          node, _sig = sigs.first #: as [Prism::CallNode, RBI::Sig]
          insert_pos = node.location.start_offset

          if sigs.any? { |_, sig| sig.without_runtime }
            @rewriter << Source::Insert.new(insert_pos, "# @without_runtime\n")
          end

          if sigs.any? { |_, sig| sig.is_final }
            @rewriter << Source::Insert.new(insert_pos, "# @final\n")
          end

          if sigs.any? { |_, sig| sig.is_abstract }
            @rewriter << Source::Insert.new(insert_pos, "# @abstract\n")
          end

          if sigs.any? { |_, sig| sig.is_override }
            @rewriter << if sigs.any? { |_, sig| sig.allow_incompatible_override }
              Source::Insert.new(insert_pos, "# @override(allow_incompatible: true)\n")
            else
              Source::Insert.new(insert_pos, "# @override\n")
            end
          end

          if sigs.any? { |_, sig| sig.is_overridable }
            @rewriter << Source::Insert.new(insert_pos, "# @overridable\n")
          end
        end
      end
    end
  end
end
