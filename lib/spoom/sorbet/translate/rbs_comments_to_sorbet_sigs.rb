# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      class RBSCommentsToSorbetSigs < Translator
        include Spoom::RBS::ExtractRBSComments

        #: (String, file: String, ?max_line_length: Integer?) -> void
        def initialize(ruby_contents, file:, max_line_length: nil)
          super(ruby_contents, file: file)

          @max_line_length = max_line_length
        end

        # @override
        #: (Prism::ProgramNode node) -> void
        def visit_program_node(node)
          # Process all type aliases from the entire file first
          apply_type_aliases(@comments)

          # Now process the rest of the file with type aliases available
          super
        end

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
          rewrite_def(node, node_rbs_comments(node))
        end

        # @override
        #: (Prism::CallNode node) -> void
        def visit_call_node(node)
          case node.message
          when "attr_reader", "attr_writer", "attr_accessor"
            visit_attr(node)
          else
            def_node = node.arguments&.arguments&.first
            if def_node&.is_a?(Prism::DefNode)
              rewrite_def(def_node, node_rbs_comments(node))
              return
            end

            super
          end
        end

        private

        #: (Prism::CallNode) -> void
        def visit_attr(node)
          comments = node_rbs_comments(node)
          return if comments.empty?

          return if comments.signatures.empty?

          comments.signatures.each do |signature|
            attr_type = ::RBS::Parser.parse_type(signature.string)
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

            apply_member_annotations(comments.method_annotations, sig)

            @rewriter << Source::Replace.new(
              signature.location.start_offset,
              signature.location.end_offset,
              sig.string(max_line_length: @max_line_length),
            )
          rescue ::RBS::ParsingError, ::RBI::Error
            # Ignore signatures with errors
            next
          end
        end

        #: (Prism::DefNode, RBS::Comments) -> void
        def rewrite_def(def_node, comments)
          return if comments.empty?
          return if comments.signatures.empty?

          builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
          builder.visit(def_node)
          rbi_node = builder.tree.nodes.first #: as RBI::Method

          comments.signatures.each do |signature|
            begin
              method_type = ::RBS::Parser.parse_method_type(signature.string)
            rescue ::RBS::ParsingError
              next
            end

            translator = RBI::RBS::MethodTypeTranslator.new(rbi_node)

            begin
              translator.visit(method_type)
            rescue ::RBI::Error
              next
            end

            sig = translator.result

            apply_member_annotations(comments.method_annotations, sig)

            @rewriter << Source::Replace.new(
              signature.location.start_offset,
              signature.location.end_offset,
              sig.string(max_line_length: @max_line_length),
            )
          end
        end

        #: (Prism::ClassNode | Prism::ModuleNode | Prism::SingletonClassNode) -> void
        def apply_class_annotations(node)
          comments = node_rbs_comments(node)
          return if comments.empty?

          indent = " " * (node.location.start_column + 2)
          insert_pos = case node
          when Prism::ClassNode
            (node.superclass || node.constant_path).location.end_offset
          when Prism::ModuleNode
            node.constant_path.location.end_offset
          when Prism::SingletonClassNode
            node.expression.location.end_offset
          end

          class_annotations = comments.class_annotations
          if class_annotations.any?
            unless already_extends?(node, /^(::)?T::Helpers$/)
              @rewriter << Source::Insert.new(insert_pos, "\n#{indent}extend T::Helpers\n")
            end

            class_annotations.reverse_each do |annotation|
              from = adjust_to_line_start(annotation.location.start_offset)
              to = adjust_to_line_end(annotation.location.end_offset)

              content = case annotation.string
              when "@abstract"
                "abstract!"
              when "@interface"
                "interface!"
              when "@sealed"
                "sealed!"
              when "@final"
                "final!"
              when /^@requires_ancestor: /
                srb_type = ::RBS::Parser.parse_type(annotation.string.delete_prefix("@requires_ancestor: "))
                rbs_type = RBI::RBS::TypeTranslator.translate(srb_type)
                "requires_ancestor { #{rbs_type} }"
              else
                next
              end

              @rewriter << Source::Delete.new(from, to)

              newline = node.body.nil? ? "" : "\n"
              @rewriter << Source::Insert.new(insert_pos, "\n#{indent}#{content}#{newline}")
            rescue ::RBS::ParsingError, ::RBI::Error
              # Ignore annotations with errors
              next
            end
          end

          signatures = comments.signatures
          if signatures.any?
            signatures.each do |signature|
              type_params = ::RBS::Parser.parse_type_params(signature.string)
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
              rescue ::RBS::ParsingError, ::RBI::Error
                # Ignore signatures with errors
                next
              end
            end
          end
        end

        #: (Array[RBS::Annotation], RBI::Sig) -> void
        def apply_member_annotations(annotations, sig)
          annotations.each do |annotation|
            case annotation.string
            when "@abstract"
              sig.is_abstract = true
            when "@final"
              sig.is_final = true
            when "@override"
              sig.is_override = true
            when "@override(allow_incompatible: true)"
              sig.is_override = true
              sig.allow_incompatible_override = true
            when "@override(allow_incompatible: :visibility)"
              sig.is_override = true
              sig.allow_incompatible_override_visibility = true
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

        #: (Array[Prism::Comment]) -> Array[RBS::TypeAlias]
        def collect_type_aliases(comments)
          type_aliases = [] #: Array[RBS::TypeAlias]

          return type_aliases if comments.empty?

          continuation_comments = [] #: Array[Prism::Comment]

          comments.reverse_each do |comment|
            string = comment.slice

            if string.start_with?("#:")
              string = string.delete_prefix("#:").strip
              location = comment.location

              if string.start_with?("type ")
                continuation_comments.reverse_each do |continuation_comment|
                  string = "#{string}#{continuation_comment.slice.delete_prefix("#|")}"
                  location = location.join(continuation_comment.location)
                end

                type_aliases << Spoom::RBS::TypeAlias.new(string, location)
              end

              # Clear the continuation comments regardless of whether we found a type alias or not
              continuation_comments.clear
            elsif string.start_with?("#|")
              continuation_comments << comment
            else
              continuation_comments.clear
            end
          end

          type_aliases
        end

        #: (Array[Prism::Comment]) -> void
        def apply_type_aliases(comments)
          type_aliases = collect_type_aliases(comments)

          type_aliases.each do |type_alias|
            indent = " " * type_alias.location.start_column
            insert_pos = adjust_to_line_start(type_alias.location.start_offset)

            from = insert_pos
            to = adjust_to_line_end(type_alias.location.end_offset)

            *, decls = ::RBS::Parser.parse_signature(type_alias.string)

            # We only expect there to be a single type alias declaration
            next unless decls.size == 1 && decls.first.is_a?(::RBS::AST::Declarations::TypeAlias)

            rbs_type = decls.first
            sorbet_type = RBI::RBS::TypeTranslator.translate(rbs_type.type)

            alias_name = ::RBS::TypeName.new(
              namespace: rbs_type.name.namespace,
              name: rbs_type.name.name.to_s.gsub(/(?:^|_)([a-z\d]*)/i) do |match|
                match = match.delete_prefix("_")
                !match.empty? ? match[0].upcase.concat(match[1..-1]) : +""
              end,
            )

            @rewriter << Source::Delete.new(from, to)
            content = "#{indent}#{alias_name} = T.type_alias { #{sorbet_type.to_rbi} }\n"
            @rewriter << Source::Insert.new(insert_pos, content)
          rescue ::RBS::ParsingError, ::RBI::Error
            # Ignore type aliases with errors
            next
          end
        end
      end
    end
  end
end
