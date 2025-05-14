# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      class RBSCommentsToSorbetSigs < Translator
        # @override
        #: (Prism::ClassNode node) -> void
        def visit_class_node(node)
          apply_class_annotations(node)

          super
        end

        # @override
        #: (Prism::ModuleNode node) -> void
        def visit_module_node(node)
          apply_class_annotations(node)

          super
        end

        # @override
        #: (Prism::SingletonClassNode node) -> void
        def visit_singleton_class_node(node)
          apply_class_annotations(node)

          super
        end

        # @override
        #: (Prism::DefNode node) -> void
        def visit_def_node(node)
          comments = node_comments(node)
          return if comments.empty?

          annotations = comments.select { |c| c.slice.start_with?("# @") }
          signatures = comments.select { |c| c.slice.start_with?("#: ") }

          return if signatures.empty?

          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(node)
          rbi_node = builder.tree.nodes.first #: as RBI::Method

          signatures.each do |signature|
            method_type = ::RBS::Parser.parse_method_type(signature.slice.delete_prefix("#: "))
            translator = RBI::RBS::MethodTypeTranslator.new(rbi_node)
            translator.visit(method_type)
            sig = translator.result
            apply_member_annotations(annotations, sig)

            @rewriter << Source::Replace.new(
              signature.location.start_offset,
              signature.location.end_offset,
              sig.string,
            )
          rescue ::RBS::ParsingError
            # Ignore signatures with errors
            next
          end
        end

        # @override
        #: (Prism::CallNode node) -> void
        def visit_call_node(node)
          case node.message
          when "attr_reader", "attr_writer", "attr_accessor"
            visit_attr(node)
          else
            super
          end
        end

        private

        #: (Prism::CallNode) -> void
        def visit_attr(node)
          comments = node_comments(node)
          return if comments.empty?

          annotations = comments.select { |c| c.slice.start_with?("# @") }
          signatures = comments.select { |c| c.slice.start_with?("#: ") }

          return if signatures.empty?

          signatures.each do |signature|
            attr_type = ::RBS::Parser.parse_type(signature.slice.delete_prefix("#: "))
            sig = RBI::Sig.new

            if node.message == "attr_writer"
              if node.arguments&.arguments&.size != 1
                raise Error, "AttrWriter must have exactly one name"
              end

              name = node.arguments&.arguments&.first #: as Prism::SymbolNode
              sig.params << RBI::SigParam.new(
                name.slice[1..-1], #: as String
                RBI::RBS::TypeTranslator.translate(attr_type),
              )
            end

            sig.return_type = RBI::RBS::TypeTranslator.translate(attr_type)

            apply_member_annotations(annotations, sig)

            @rewriter << Source::Replace.new(
              signature.location.start_offset,
              signature.location.end_offset,
              sig.string,
            )
          end
        end

        #: (Prism::Node) -> Array[Prism::Comment]
        def node_comments(node)
          comments = []

          start_line = node.location.start_line
          start_line -= 1 unless @comments_by_line.key?(start_line)

          start_line.downto(1) do |line|
            comment = @comments_by_line[line]
            break unless comment

            comments.unshift(comment)
            @comments_by_line.delete(line)
          end

          comments
        end

        #: (Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode) -> void
        def apply_class_annotations(node)
          comments = node_comments(node)
          return if comments.empty?

          annotations = comments.select do |c|
            case c.slice.delete_prefix("# ")
            when "@abstract", "@interface", "@sealed", "@final", /^@requires_ancestor: /
              true
            else
              false
            end
          end

          indent = " " * (node.location.start_column + 2)
          insert_pos = case node
          when Prism::ClassNode
            (node.superclass || node.constant_path).location.end_offset
          when Prism::ModuleNode
            node.constant_path.location.end_offset
          when Prism::SingletonClassNode
            node.expression.location.end_offset
          end

          if annotations.any?
            unless already_extends?(node, /^(::)?T::Helpers$/)
              @rewriter << Source::Insert.new(insert_pos, "\n#{indent}extend T::Helpers\n")
            end

            annotations.each do |annotation|
              from = adjust_to_line_start(annotation.location.start_offset)
              to = adjust_to_line_end(annotation.location.end_offset)
              @rewriter << Source::Delete.new(from, to)

              content = case annotation.slice.delete_prefix("# ")
              when "@abstract"
                "abstract!"
              when "@interface"
                "interface!"
              when "@sealed"
                "sealed!"
              when "@final"
                "final!"
              when /^@requires_ancestor: /
                srb_type = ::RBS::Parser.parse_type(annotation.slice.delete_prefix("# @requires_ancestor: "))
                rbs_type = RBI::RBS::TypeTranslator.translate(srb_type)
                "requires_ancestor { #{rbs_type} }"
              end

              newline = node.body.nil? ? "" : "\n"
              @rewriter << Source::Insert.new(insert_pos, "\n#{indent}#{content}#{newline}")
            end
          end

          signatures = comments.select { |c| c.slice.start_with?("#: ") }
          if signatures.any?
            signatures.each do |signature|
              type_params = ::RBS::Parser.parse_type_params(signature.slice.delete_prefix("#: "))
              next if type_params.empty?

              from = adjust_to_line_start(signature.location.start_offset)
              to = adjust_to_line_end(signature.location.end_offset)
              @rewriter << Source::Delete.new(from, to)

              unless already_extends?(node, /^(::)?T::Generic$/)
                @rewriter << Source::Insert.new(insert_pos, "\n#{indent}extend T::Generic\n")
              end

              type_params.each do |type_param|
                type_member = "#{type_param.name} = type_member"

                case type_param.variance
                when :covariant
                  type_member = "#{type_member}(:out)"
                when :contravariant
                  type_member = "#{type_member}(:in)"
                end

                if type_param.upper_bound || type_param.default_type
                  if type_param.upper_bound
                    rbs_type = RBI::RBS::TypeTranslator.translate(type_param.upper_bound)
                    type_member = "#{type_member} {{ upper: #{rbs_type} }}"
                  end

                  if type_param.default_type
                    rbs_type = RBI::RBS::TypeTranslator.translate(type_param.default_type)
                    type_member = "#{type_member} {{ fixed: #{rbs_type} }}"
                  end
                end

                newline = node.body.nil? ? "" : "\n"
                @rewriter << Source::Insert.new(insert_pos, "\n#{indent}#{type_member}#{newline}")
              end
            end
          end
        end

        #: (Array[Prism::Comment], RBI::Sig) -> void
        def apply_member_annotations(comments, sig)
          comments.each do |comment|
            case comment.slice.delete_prefix("# ")
            when "@abstract"
              sig.is_abstract = true
            when "@final"
              sig.is_final = true
            when "@override"
              sig.is_override = true
            when "@override(allow_incompatible: true)"
              sig.is_override = true
              sig.allow_incompatible_override = true
            when "@overridable"
              sig.is_overridable = true
            when "@without_runtime"
              sig.without_runtime = true
            end
          end
        end

        #: (Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode, Regexp) -> bool
        def already_extends?(node, constant_regex)
          node.child_nodes.any? do |c|
            next false unless c.is_a?(Prism::CallNode)
            next false unless c.message == "extend"
            next false unless c.receiver.nil? || c.receiver.is_a?(Prism::SelfNode)
            next false unless c.arguments&.arguments&.size == 1

            arg = c.arguments&.arguments&.first
            next false unless arg.is_a?(Prism::ConstantPathNode)
            next false unless arg.slice.match?(constant_regex)

            true
          end
        end
      end
    end
  end
end
