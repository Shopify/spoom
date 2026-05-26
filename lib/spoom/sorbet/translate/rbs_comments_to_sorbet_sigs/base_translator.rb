# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      module RBSCommentsToSorbetSigs
        # @abstract
        class BaseTranslator < Translator
          include Spoom::RBS::ExtractRBSComments

          #: (String, file: String, ?options: Options) -> void
          def initialize(
            ruby_contents,
            file:,
            options: Options.default
          )
            super(ruby_contents, file:)

            @max_line_length = case (format = options.output_format)
            when HumanReadableRBIFormat
              format.max_line_length
            else
              nil
            end #: Integer?

            @overloads_strategy = options.overloads_strategy #: Symbol
            @translate_abstract_methods = options.translate_abstract_methods #: bool
            @options = options #: Options
            @type_translator = RBI::RBS::TypeTranslator.new(options: options.rbi_options) #: RBI::RBS::TypeTranslator
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

            signatures = apply_overloads_strategy(
              comments.signatures,
              method_name: node.message.to_s,
              location: "#{@file}:#{node.location.start_line}",
            )

            known_annotations = nil #: Array[Spoom::RBS::Annotation]?

            signatures.each do |signature|
              attr_type = ::RBS::Parser.parse_type(signature.string)
              sig = RBI::Sig.new

              if node.message == "attr_writer"
                if node.arguments&.arguments&.size != 1
                  raise Error, "AttrWriter must have exactly one name"
                end

                name = node.arguments&.arguments&.first #: as Prism::SymbolNode
                sig.params << RBI::SigParam.new(
                  name.slice[1..-1], #: as String
                  @type_translator.translate(attr_type),
                )
              end

              sig.return_type = @type_translator.translate(attr_type)

              known_annotations = apply_member_annotations(comments.method_annotations, sig)

              @rewriter << Source::Replace.new(
                signature.location.start_offset,
                signature.location.end_offset,
                pad_out_line_count(of: sig.string(max_line_length: @max_line_length), to_height_of: signature),
              )
            rescue ::RBS::ParsingError, ::RBI::Error
              # Ignore signatures with errors
              next
            end

            if known_annotations
              rewrite_member_annotations(comments.method_annotations, known: known_annotations)
            end
          end

          #: (Prism::DefNode, Spoom::RBS::Comments) -> void
          def rewrite_def(def_node, comments)
            return if comments.empty?
            return if comments.signatures.empty?
            return if !@translate_abstract_methods && comments.method_annotations.any?(&:abstract?)

            signatures = apply_overloads_strategy(
              comments.signatures,
              method_name: def_node.name.to_s,
              location: "#{@file}:#{def_node.location.start_line}",
            )

            builder = RBI::Parser::TreeBuilder.new(@ruby_contents, comments: [], file: @file)
            builder.visit(def_node)
            rbi_node = builder.tree.nodes.first #: as RBI::Method

            known_annotations = nil #: Array[Spoom::RBS::Annotation]?

            signatures.each do |signature|
              begin
                method_type = ::RBS::Parser.parse_method_type(signature.string)
              rescue ::RBS::ParsingError
                next
              end

              translator = RBI::RBS::MethodTypeTranslator.new(rbi_node, options: @options.rbi_options)

              begin
                translator.visit(method_type)
              rescue ::RBI::Error
                next
              end

              sig = translator.result

              known_annotations = apply_member_annotations(comments.method_annotations, sig)

              # Sorbet runtime doesn't support `sig` on `method_added` or
              # `singleton_method_added`, so we always use `without_runtime` for them.
              if def_node.name == :method_added || def_node.name == :singleton_method_added
                sig.without_runtime = true
              end

              @rewriter << Source::Replace.new(
                signature.location.start_offset,
                signature.location.end_offset,
                pad_out_line_count(of: sig.string(max_line_length: @max_line_length), to_height_of: signature),
              )
            end

            if known_annotations
              rewrite_member_annotations(comments.method_annotations, known: known_annotations)
            end
          end

          #: (Array[Spoom::RBS::Signature], method_name: String, location: String) -> Array[Spoom::RBS::Signature]
          def apply_overloads_strategy(signatures, method_name:, location:)
            return signatures if signatures.size <= 1

            case @overloads_strategy
            when :translate_all
              signatures
            when :translate_last
              others = signatures[0...-1] #: as !nil
              others.each { |signature| rewrite_discarded_overload(signature) }

              kept = signatures.last #: as Spoom::RBS::Signature
              [kept]
            else # :raise
              raise Error, "Method `#{method_name}` at #{location} has multiple overloaded signatures"
            end
          end

          # Called for every overloaded method sig that we discard because it wasn't the last one.
          # @abstract
          #: (Spoom::RBS::Signature) -> void
          def rewrite_discarded_overload(signature) = raise

          #: (PrismTypes::anyScopeNode) -> void
          def apply_class_annotations(node)
            comments = node_rbs_comments(node)
            return if comments.empty?

            insert_pos = case node
            when Prism::ClassNode
              (node.superclass || node.constant_path).location.end_offset
            when Prism::ModuleNode
              node.constant_path.location.end_offset
            when Prism::SingletonClassNode
              node.expression.location.end_offset
            end

            # Only translate (and `extend T::Helpers`) when there's at least one *known* class
            # annotation. A node with only unknown annotations (e.g. `@private`) is left untouched.
            if comments.class_annotations.any?
              unless already_extends?(node, /^(::)?T::Helpers$/)
                extend_with("T::Helpers", into: node, at: insert_pos)
              end

              comments.annotations.reverse_each do |annotation|
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
                  rbs_type = @type_translator.translate(srb_type)
                  "requires_ancestor { #{rbs_type} }"
                else
                  apply_class_annotation(annotation, parent_node: node, insert_pos:, sorbet_replacement: nil)
                  next
                end

                apply_class_annotation(annotation, parent_node: node, insert_pos:, sorbet_replacement: content)
              rescue ::RBS::ParsingError, ::RBI::Error
                apply_class_annotation(annotation, parent_node: node, insert_pos:, sorbet_replacement: nil)
                next
              end
            end

            signatures = comments.signatures
            if signatures.any?
              signatures.each do |signature|
                # Only type param signatures (e.g. `#: [A, B]`) are valid on class/module nodes
                next unless signature.string.start_with?("[")

                type_params = ::RBS::Parser.parse_type_params(signature.string)
                rewrite_type_params_signature(signature, type_params:)
                next if type_params.empty?

                if @options.erase_generic_types
                  type_params.each do |type_param|
                    insert_type_member(
                      "#{type_param.name} = ::T.type_alias { ::T.anything }",
                      parent_node: node,
                      insert_pos:,
                    )
                  end

                  next
                end

                unless already_extends?(node, /^(::)?T::Generic$/)
                  extend_with("T::Generic", into: node, at: insert_pos)
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
                      rbs_type = @type_translator.translate(type_param.upper_bound)
                      type_member = "#{type_member} {{ upper: #{rbs_type} }}"
                    end

                    if type_param.default_type
                      rbs_type = @type_translator.translate(type_param.default_type)
                      type_member = "#{type_member} {{ fixed: #{rbs_type} }}"
                    end
                  end

                  insert_type_member(type_member, parent_node: node, insert_pos:)
                rescue ::RBS::ParsingError, ::RBI::Error
                  # Ignore signatures with errors
                  next
                end
              end
            end
          end

          # @param is_known: true if this is an RBS annotation that we recognize
          #                  false for some other `@`-prefixed thing, like a documentation `@param` tag.
          # @abstract
          #: (
          #|   Spoom::RBS::Annotation,
          #|   parent_node: PrismTypes::anyScopeNode,
          #|   insert_pos: Integer,
          #|   sorbet_replacement: String?
          #| ) -> void
          def apply_class_annotation(annotation, parent_node:, insert_pos:, sorbet_replacement:) = raise

          # Rewrites the `#: [...]` type params comment (e.g. delete it, or mark it as translated).
          # @abstract
          #: (Spoom::RBS::Signature, type_params: Array[::RBS::AST::TypeParam]) -> void
          def rewrite_type_params_signature(signature, type_params:) = raise

          # Inserts a single `type_member` declaration into the class/module body.
          # @abstract
          #: (String type_member, parent_node: PrismTypes::anyScopeNode, insert_pos: Integer) -> void
          def insert_type_member(type_member, parent_node:, insert_pos:) = raise

          #: (Array[Spoom::RBS::Annotation], RBI::Sig) -> Array[Spoom::RBS::Annotation]
          def apply_member_annotations(annotations, sig)
            known = [] #: Array[Spoom::RBS::Annotation]

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
              else
                next
              end

              known << annotation
            end

            known
          end

          # Rewrites the member annotation comments in the source. Called once per method,
          # regardless of how many overloaded signatures share the annotations, to avoid
          # emitting duplicate markers.
          #
          #: (Array[Spoom::RBS::Annotation], known: Array[Spoom::RBS::Annotation]) -> void
          def rewrite_member_annotations(annotations, known:)
            annotations.each do |annotation|
              rewrite_annotation(annotation, is_known: known.include?(annotation))
            end
          end

          # @param is_known: true if this is an RBS annotation that we recognize
          #                  false for some other `@`-prefixed thing, like a documentation `@param` tag.
          # @overridable
          #: (Spoom::RBS::Annotation, is_known: bool) -> void
          def rewrite_annotation(annotation, is_known:) = nil # no-op

          # @abstract
          #: (String mixin_name, into: PrismTypes::anyScopeNode, at: Integer) -> void
          def extend_with(mixin_name, into:, at:) = raise

          #: (PrismTypes::anyScopeNode, Regexp) -> bool
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

          #: (Array[Prism::Comment]) -> Array[Spoom::RBS::TypeAlias]
          def collect_type_aliases(comments)
            type_aliases = [] #: Array[Spoom::RBS::TypeAlias]

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
              sorbet_type = @type_translator.translate(rbs_type.type)

              alias_name = ::RBS::TypeName.new(
                namespace: rbs_type.name.namespace,
                name: rbs_type.name.name.to_s.gsub(/(?:^|_)([a-z\d]*)/i) do |match|
                  match = match.delete_prefix("_")
                  !match.empty? ? match[0].upcase.concat(match[1..-1]) : +""
                end,
              )

              @rewriter << Source::Delete.new(from, to)
              content = "#{indent}#{alias_name} = T.type_alias { #{sorbet_type.to_rbi} }\n"
              content = pad_out_line_count(of: content, to_height_of: type_alias)
              @rewriter << Source::Insert.new(insert_pos, content)
            rescue ::RBS::ParsingError, ::RBI::Error
              # Ignore type aliases with errors
              next
            end
          end

          # @overridable
          #: (of: String, to_height_of: Spoom::RBS::Comment) -> String
          def pad_out_line_count(of:, to_height_of:)
            replacement = of

            # no-op implementation
            replacement
          end
        end
      end
    end
  end
end
