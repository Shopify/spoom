# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      # Converts all `sig` nodes to RBS comments in the given Ruby code.
      # It also handles type members and class annotations.
      class SorbetSigsToRBSComments < Translator
        #: (
        #|   String,
        #|   file: String,
        #|   positional_names: bool,
        #|   ?max_line_length: Integer?,
        #|   ?translate_generics: bool,
        #|   ?translate_helpers: bool,
        #|   ?translate_abstract_methods: bool
        #| ) -> void
        def initialize(
          ruby_contents,
          file:,
          positional_names:,
          max_line_length: nil,
          translate_generics: true,
          translate_helpers: true,
          translate_abstract_methods: true
        )
          super(ruby_contents, file: file)

          @positional_names = positional_names #: bool
          @last_sigs = [] #: Array[[Prism::CallNode, RBI::Sig]]
          @class_annotations = [] #: Array[Prism::CallNode]
          @type_members = [] #: Array[String]
          @extend_t_helpers = [] #: Array[Prism::CallNode]
          @extend_t_generics = [] #: Array[Prism::CallNode]
          @seen_mixes_in_class_methods = false #: bool
          @max_line_length = max_line_length #: Integer?

          @translate_generics = translate_generics #: bool
          @translate_helpers = translate_helpers #: bool
          @translate_abstract_methods = translate_abstract_methods #: bool
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
          last_sigs = collect_last_sigs
          return if last_sigs.empty?

          apply_member_annotations(last_sigs)

          # Build the RBI::Method node so we can print the method signature as RBS.
          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Method

          last_sigs.each do |node, sig|
            next if sig.is_abstract && !@translate_abstract_methods

            out = rbs_print(node.location.start_column) do |printer|
              printer.print_method_sig(rbi_node, sig)
            end
            @rewriter << Source::Replace.new(node.location.start_offset, node.location.end_offset, out)
          end

          if @translate_abstract_methods && last_sigs.any? { |_, sig| sig.is_abstract }
            @rewriter << Source::Replace.new(
              node.rparen_loc&.end_offset || node.name_loc.end_offset,
              node.location.end_offset - 1,
              if node.name.end_with?("=")
                indent = " " * node.location.start_column
                "\n#{indent}  raise NotImplementedError, \"Abstract method called\"\n#{indent}end"
              else
                " = raise NotImplementedError, \"Abstract method called\""
              end,
            )
          end
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
            @class_annotations << node
          when "mixes_in_class_methods"
            @seen_mixes_in_class_methods = true
          else
            super
          end
        end

        # @override
        #: (Prism::ConstantWriteNode) -> void
        def visit_constant_write_node(node)
          return super unless @translate_generics

          call = node.value
          return super unless call.is_a?(Prism::CallNode)
          return super unless call.message == "type_member"

          @type_members << build_type_member_string(node)

          from = adjust_to_line_start(node.location.start_offset)
          to = adjust_to_line_end(node.location.end_offset)
          to = adjust_to_new_line(to)

          @rewriter << Source::Delete.new(from, to)
        end

        private

        #: (Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode) { -> void } -> void
        def visit_scope(node, &block)
          old_class_annotations = @class_annotations
          @class_annotations = []
          old_type_members = @type_members
          @type_members = []
          old_extend_t_helpers = @extend_t_helpers
          @extend_t_helpers = []
          old_extend_t_generics = @extend_t_generics
          @extend_t_generics = []
          old_seen_mixes_in_class_methods = @seen_mixes_in_class_methods
          @seen_mixes_in_class_methods = false

          yield

          if @translate_generics
            delete_extend_t_generics

            if @type_members.any?
              indent = " " * node.location.start_column
              @rewriter << Source::Insert.new(node.location.start_offset, "#: [#{@type_members.join(", ")}]\n#{indent}")
            end
          end

          if @translate_helpers
            unless @seen_mixes_in_class_methods
              delete_extend_t_helpers
            end

            @class_annotations.each do |call|
              apply_class_annotation(node, call)
            end
          end

          @class_annotations = old_class_annotations
          @type_members = old_type_members
          @extend_t_helpers = old_extend_t_helpers
          @extend_t_generics = old_extend_t_generics
          @seen_mixes_in_class_methods = old_seen_mixes_in_class_methods
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

          last_sigs = collect_last_sigs
          return if last_sigs.empty?
          return if last_sigs.any? { |_, sig| sig.is_abstract }

          apply_member_annotations(last_sigs)

          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Attr

          last_sigs.each do |node, sig|
            out = rbs_print(node.location.start_column) do |printer|
              printer.print_attr_sig(rbi_node, sig)
            end
            @rewriter << Source::Replace.new(node.location.start_offset, node.location.end_offset, out)
          end
        end

        #: (Prism::CallNode node) -> void
        def visit_extend(node)
          raise Error, "Expected extend" unless node.message == "extend"

          return unless node.receiver.nil? || node.receiver.is_a?(Prism::SelfNode)
          return unless node.arguments&.arguments&.size == 1

          arg = node.arguments&.arguments&.first
          return unless arg.is_a?(Prism::ConstantPathNode)

          case arg.slice
          when /^(::)?T::Helpers$/
            @extend_t_helpers << node
          when /^(::)?T::Generic$/
            @extend_t_generics << node
          end
        end

        #: (Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode, Prism::CallNode) -> void
        def apply_class_annotation(parent, node)
          unless node.message == "abstract!" || node.message == "interface!" || node.message == "sealed!" ||
              node.message == "final!" || node.message == "requires_ancestor"
            raise Error, "Expected abstract!, interface!, sealed!, final!, or requires_ancestor"
          end

          return unless node.receiver.nil? || node.receiver.is_a?(Prism::SelfNode)
          return unless node.arguments.nil?

          indent = " " * parent.location.start_column

          case node.message
          when "abstract!"
            @rewriter << Source::Insert.new(parent.location.start_offset, "# @abstract\n#{indent}")
          when "interface!"
            @rewriter << Source::Insert.new(parent.location.start_offset, "# @interface\n#{indent}")
          when "sealed!"
            @rewriter << Source::Insert.new(parent.location.start_offset, "# @sealed\n#{indent}")
          when "final!"
            @rewriter << Source::Insert.new(parent.location.start_offset, "# @final\n#{indent}")
          when "requires_ancestor"
            block = node.block
            return unless block.is_a?(Prism::BlockNode)

            body = block.body
            return unless body.is_a?(Prism::StatementsNode)
            return unless body.body.size == 1

            arg = body.body.first #: as Prism::Node
            srb_type = RBI::Type.parse_node(arg)
            @rewriter << Source::Insert.new(
              parent.location.start_offset,
              "# @requires_ancestor: #{srb_type.rbs_string}\n#{indent}",
            )
          end

          from = adjust_to_line_start(node.location.start_offset)
          to = adjust_to_line_end(node.location.end_offset)
          to = adjust_to_new_line(to)

          @rewriter << Source::Delete.new(from, to)
        end

        #: (Array[[Prism::CallNode, RBI::Sig]]) -> void
        def apply_member_annotations(sigs)
          return if sigs.empty?

          node, _sig = sigs.first #: as [Prism::CallNode, RBI::Sig]
          insert_pos = node.location.start_offset

          indent = " " * node.location.start_column

          if sigs.any? { |_, sig| sig.without_runtime }
            @rewriter << Source::Insert.new(insert_pos, "# @without_runtime\n#{indent}")
          end

          if sigs.any? { |_, sig| sig.is_final }
            @rewriter << Source::Insert.new(insert_pos, "# @final\n#{indent}")
          end

          if sigs.any? { |_, sig| sig.is_abstract } && @translate_abstract_methods
            @rewriter << Source::Insert.new(insert_pos, "# @abstract\n#{indent}")
          end

          if sigs.any? { |_, sig| sig.is_override }
            @rewriter << if sigs.any? { |_, sig| sig.allow_incompatible_override }
              Source::Insert.new(insert_pos, "# @override(allow_incompatible: true)\n#{indent}")
            elsif sigs.any? { |_, sig| sig.allow_incompatible_override_visibility }
              Source::Insert.new(insert_pos, "# @override(allow_incompatible: :visibility)\n#{indent}")
            else
              Source::Insert.new(insert_pos, "# @override\n#{indent}")
            end
          end

          if sigs.any? { |_, sig| sig.is_overridable }
            @rewriter << Source::Insert.new(insert_pos, "# @overridable\n")
          end
        end

        #: (Prism::ConstantWriteNode) -> String
        def build_type_member_string(node)
          call = node.value
          raise Error, "Expected a call node" unless call.is_a?(Prism::CallNode)
          raise Error, "Expected type_member" unless call.message == "type_member"

          type_member = node.name.to_s

          arg = call.arguments&.arguments&.first
          if arg.is_a?(Prism::SymbolNode)
            case arg.slice
            when ":in"
              type_member = "in #{type_member}"
            when ":out"
              type_member = "out #{type_member}"
            else
              raise Error, "Unknown type member variance: #{arg.slice}"
            end
          end

          block = call.block
          return type_member unless block.is_a?(Prism::BlockNode)

          body = block.body
          return type_member unless body.is_a?(Prism::StatementsNode)
          return type_member unless body.body.size == 1

          hash = body.body.first
          return type_member unless hash.is_a?(Prism::HashNode)

          hash.elements.each do |element|
            next unless element.is_a?(Prism::AssocNode)

            type = RBI::Type.parse_node(element.value)

            case element.key.slice
            when "upper:"
              type_member = "#{type_member} < #{type.rbs_string}"
            when "fixed:"
              type_member = "#{type_member} = #{type.rbs_string}"
            end
          end

          type_member
        end

        #: -> void
        def delete_extend_t_helpers
          @extend_t_helpers.each do |helper|
            from = adjust_to_line_start(helper.location.start_offset)
            to = adjust_to_line_end(helper.location.end_offset)
            to = adjust_to_new_line(to)
            @rewriter << Source::Delete.new(from, to)
          end

          @extend_t_helpers.clear
        end

        #: -> void
        def delete_extend_t_generics
          @extend_t_generics.each do |generic|
            from = adjust_to_line_start(generic.location.start_offset)
            to = adjust_to_line_end(generic.location.end_offset)
            to = adjust_to_new_line(to)
            @rewriter << Source::Delete.new(from, to)
          end

          @extend_t_generics.clear
        end

        # Collects the last signatures visited and clears the current list
        #: -> Array[[Prism::CallNode, RBI::Sig]]
        def collect_last_sigs
          last_sigs = @last_sigs
          @last_sigs = []
          last_sigs
        end

        #: (Integer) { (RBI::RBSPrinter) -> void } -> String
        def rbs_print(indent, &block)
          out = StringIO.new
          p = RBI::RBSPrinter.new(out: out, positional_names: @positional_names, max_line_length: @max_line_length)
          block.call(p)
          string = out.string

          string.lines.map.with_index do |line, index|
            if index == 0
              "#: #{line}"
            else
              "#{" " * indent}#| #{line}"
            end
          end.join + "\n"
        end
      end
    end
  end
end
