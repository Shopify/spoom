# typed: strict
# frozen_string_literal: true

module Spoom
  module Typecheck
    class Printer < Visitor
      extend T::Sig

      class Error < Spoom::Error; end

      sig { params(out: T.any(IO, StringIO)).void }
      def initialize(out: $stdout)
        super()

        @out = out
        @current_indent = T.let(0, Integer)
        @in_visibility_group = T.let(false, T::Boolean)
      end

      # Printing

      sig { void }
      def indent
        @current_indent += 2
      end

      sig { void }
      def dedent
        @current_indent -= 2
      end

      # Print a string without indentation nor `\n` at the end.
      sig { params(string: String).void }
      def print(string)
        @out.print(string)
      end

      # Print a string without indentation but with a `\n` at the end.
      sig { params(string: T.nilable(String)).void }
      def printn(string = nil)
        print(string) if string
        print("\n")
      end

      # Print a string with indentation but without a `\n` at the end.
      sig { params(string: T.nilable(String)).void }
      def printt(string = nil)
        print(" " * @current_indent)
        print(string) if string
      end

      # Print a string with indentation and `\n` at the end.
      sig { params(string: String).void }
      def printl(string)
        printt
        printn(string)
      end

      # Visit

      sig { override.params(node: T.nilable(Prism::Node)).void }
      def visit(node)
        return unless node

        super

        case node
        when Prism::ProgramNode,
             Prism::ClassNode, Prism::ModuleNode, Prism::SingletonClassNode,
             Prism::DefNode,
             Prism::StatementsNode,
             Prism::ParametersNode,
             Prism::ArgumentsNode
          # no-op
        else
          print(": #{node.spoom_type || "<NIL>"}")
        end
      end

      sig { override.params(node: Prism::AliasGlobalVariableNode).void }
      def visit_alias_global_variable_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::AliasMethodNode).void }
      def visit_alias_method_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::AlternationPatternNode).void }
      def visit_alternation_pattern_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::AndNode).void }
      def visit_and_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ArgumentsNode).void }
      def visit_arguments_node(node)
        print("(")
        node.arguments.each_with_index do |arg, i|
          print(", ") if i > 0
          visit(arg)
        end
        print(")")
      end

      sig { override.params(node: Prism::ArrayNode).void }
      def visit_array_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ArrayPatternNode).void }
      def visit_array_pattern_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::AssocNode).void }
      def visit_assoc_node(node)
        visit(node.key)
        print(": ")
        visit(node.value)
      end

      sig { override.params(node: Prism::AssocSplatNode).void }
      def visit_assoc_splat_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::BackReferenceReadNode).void }
      def visit_back_reference_read_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::BeginNode).void }
      def visit_begin_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::BlockArgumentNode).void }
      def visit_block_argument_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::BlockLocalVariableNode).void }
      def visit_block_local_variable_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::BlockNode).void }
      def visit_block_node(node)
        print(" {")

        body = T.cast(node.body, T.nilable(Prism::StatementsNode))
        if body
          print(" ")
          body.body.each do |stmt|
            visit(stmt)
          end
          print(" ")
        end
        print("}")
      end

      sig { override.params(node: Prism::BlockParameterNode).void }
      def visit_block_parameter_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::BlockParametersNode).void }
      def visit_block_parameters_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::BreakNode).void }
      def visit_break_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::CallAndWriteNode).void }
      def visit_call_and_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        if node.receiver
          visit(node.receiver)
          print(".")
        end

        method_symbol = node.spoom_method_symbol
        name = if method_symbol
          "<#{method_symbol.name}>"
        else
          node.name.to_s
        end

        print(name)
        visit(node.arguments)
        visit(node.block)
      end

      sig { override.params(node: Prism::CallOperatorWriteNode).void }
      def visit_call_operator_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::CallOrWriteNode).void }
      def visit_call_or_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::CallTargetNode).void }
      def visit_call_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::CapturePatternNode).void }
      def visit_capture_pattern_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::CaseMatchNode).void }
      def visit_case_match_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::CaseNode).void }
      def visit_case_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        symbol_def = node.spoom_symbol_def
        name = if symbol_def
          "<#{symbol_def.name}>"
        else
          node.name
        end

        superclass_node = node.superclass
        superclass_name = if superclass_node
          superclass_symbol = node.spoom_superclass_symbol
          if superclass_symbol
            "<#{superclass_symbol.name}>"
          else
            superclass_node.slice
          end
        else
          "<nil>"
        end
        printn("class #{name} < #{superclass_name}")
        indent
        visit(node.body)
        dedent
        printt("end")
      end

      sig { override.params(node: Prism::ClassVariableAndWriteNode).void }
      def visit_class_variable_and_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ClassVariableOperatorWriteNode).void }
      def visit_class_variable_operator_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ClassVariableOrWriteNode).void }
      def visit_class_variable_or_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ClassVariableReadNode).void }
      def visit_class_variable_read_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ClassVariableTargetNode).void }
      def visit_class_variable_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ClassVariableWriteNode).void }
      def visit_class_variable_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantAndWriteNode).void }
      def visit_constant_and_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantOperatorWriteNode).void }
      def visit_constant_operator_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantOrWriteNode).void }
      def visit_constant_or_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantPathAndWriteNode).void }
      def visit_constant_path_and_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantPathNode).void }
      def visit_constant_path_node(node)
        parent = node.parent
        if parent
          visit(parent)
          print("::")
        end
        print(node.name.to_s) # rubocop:disable Lint/RedundantStringCoercion
      end

      sig { override.params(node: Prism::ConstantPathOperatorWriteNode).void }
      def visit_constant_path_operator_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantPathOrWriteNode).void }
      def visit_constant_path_or_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantPathTargetNode).void }
      def visit_constant_path_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantPathWriteNode).void }
      def visit_constant_path_write_node(node)
        print("#{node.target.slice} = ")
        visit(node.value)
      end

      sig { override.params(node: Prism::ConstantReadNode).void }
      def visit_constant_read_node(node)
        print(node.name.to_s) # rubocop:disable Lint/RedundantStringCoercion
      end

      sig { override.params(node: Prism::ConstantTargetNode).void }
      def visit_constant_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ConstantWriteNode).void }
      def visit_constant_write_node(node)
        print("#{node.name} = ")
        visit(node.value)
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        print("def #{node.name}(")
        visit(node.parameters)
        printn(")")
        indent
        visit(node.body)
        dedent
        printt("end")
      end

      sig { override.params(node: Prism::DefinedNode).void }
      def visit_defined_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ElseNode).void }
      def visit_else_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::EmbeddedStatementsNode).void }
      def visit_embedded_statements_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::EmbeddedVariableNode).void }
      def visit_embedded_variable_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::EnsureNode).void }
      def visit_ensure_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::FalseNode).void }
      def visit_false_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::FindPatternNode).void }
      def visit_find_pattern_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::FlipFlopNode).void }
      def visit_flip_flop_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::FloatNode).void }
      def visit_float_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ForNode).void }
      def visit_for_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ForwardingArgumentsNode).void }
      def visit_forwarding_arguments_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ForwardingParameterNode).void }
      def visit_forwarding_parameter_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ForwardingSuperNode).void }
      def visit_forwarding_super_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::GlobalVariableAndWriteNode).void }
      def visit_global_variable_and_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::GlobalVariableOperatorWriteNode).void }
      def visit_global_variable_operator_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::GlobalVariableOrWriteNode).void }
      def visit_global_variable_or_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::GlobalVariableReadNode).void }
      def visit_global_variable_read_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::GlobalVariableTargetNode).void }
      def visit_global_variable_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::GlobalVariableWriteNode).void }
      def visit_global_variable_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::HashNode).void }
      def visit_hash_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::HashPatternNode).void }
      def visit_hash_pattern_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::IfNode).void }
      def visit_if_node(node)
        print("if ")
        visit(node.predicate)
        print(" #: #{node.spoom_type}") if node.spoom_type
        printn
        indent
        visit(node.statements)
        dedent
        if node.consequent
          printn("else")
          indent
          visit(node.consequent)
          dedent
        end
        printt("end")
      end

      sig { override.params(node: Prism::ImaginaryNode).void }
      def visit_imaginary_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ImplicitNode).void }
      def visit_implicit_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ImplicitRestNode).void }
      def visit_implicit_rest_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InNode).void }
      def visit_in_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::IndexAndWriteNode).void }
      def visit_index_and_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::IndexOperatorWriteNode).void }
      def visit_index_operator_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::IndexOrWriteNode).void }
      def visit_index_or_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::IndexTargetNode).void }
      def visit_index_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InstanceVariableAndWriteNode).void }
      def visit_instance_variable_and_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InstanceVariableOperatorWriteNode).void }
      def visit_instance_variable_operator_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InstanceVariableOrWriteNode).void }
      def visit_instance_variable_or_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InstanceVariableReadNode).void }
      def visit_instance_variable_read_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InstanceVariableTargetNode).void }
      def visit_instance_variable_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InstanceVariableWriteNode).void }
      def visit_instance_variable_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::IntegerNode).void }
      def visit_integer_node(node)
        print(node.slice)
      end

      sig { override.params(node: Prism::InterpolatedMatchLastLineNode).void }
      def visit_interpolated_match_last_line_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InterpolatedRegularExpressionNode).void }
      def visit_interpolated_regular_expression_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InterpolatedStringNode).void }
      def visit_interpolated_string_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InterpolatedSymbolNode).void }
      def visit_interpolated_symbol_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::InterpolatedXStringNode).void }
      def visit_interpolated_x_string_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::KeywordHashNode).void }
      def visit_keyword_hash_node(node)
        node.elements.each_with_index do |assoc, i|
          raise Error, "Not Yet Implemented node #{node.inspect}" unless assoc.is_a?(Prism::AssocNode)

          print(", ") if i > 0
          visit(assoc)
        end
      end

      sig { override.params(node: Prism::KeywordRestParameterNode).void }
      def visit_keyword_rest_parameter_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::LambdaNode).void }
      def visit_lambda_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::LocalVariableAndWriteNode).void }
      def visit_local_variable_and_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::LocalVariableOperatorWriteNode).void }
      def visit_local_variable_operator_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::LocalVariableOrWriteNode).void }
      def visit_local_variable_or_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::LocalVariableReadNode).void }
      def visit_local_variable_read_node(node)
        print(node.name.to_s) # rubocop:disable Lint/RedundantStringCoercion
      end

      sig { override.params(node: Prism::LocalVariableTargetNode).void }
      def visit_local_variable_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::LocalVariableWriteNode).void }
      def visit_local_variable_write_node(node)
        print("#{node.name} = ")
        visit(node.value)
      end

      sig { override.params(node: Prism::MatchLastLineNode).void }
      def visit_match_last_line_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::MatchPredicateNode).void }
      def visit_match_predicate_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::MatchRequiredNode).void }
      def visit_match_required_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::MatchWriteNode).void }
      def visit_match_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::MissingNode).void }
      def visit_missing_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        symbol_def = node.spoom_symbol_def
        name = if symbol_def
          "<#{symbol_def.name}>"
        else
          node.name
        end

        printn("module #{name}")
        indent
        visit(node.body)
        dedent
        printt("end")
      end

      sig { override.params(node: Prism::MultiTargetNode).void }
      def visit_multi_target_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::MultiWriteNode).void }
      def visit_multi_write_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::NextNode).void }
      def visit_next_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::NilNode).void }
      def visit_nil_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::NoKeywordsParameterNode).void }
      def visit_no_keywords_parameter_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::NumberedParametersNode).void }
      def visit_numbered_parameters_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::NumberedReferenceReadNode).void }
      def visit_numbered_reference_read_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::OptionalKeywordParameterNode).void }
      def visit_optional_keyword_parameter_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::OptionalParameterNode).void }
      def visit_optional_parameter_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::OrNode).void }
      def visit_or_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ParametersNode).void }
      def visit_parameters_node(node)
        parameters = [
          *node.requireds,
          *node.optionals,
          node.rest,
          *node.keywords,
          node.keyword_rest,
          node.block,
        ].compact

        parameters.each_with_index do |param, i|
          print(", ") if i > 0
          visit(param)
        end
      end

      sig { override.params(node: Prism::ParenthesesNode).void }
      def visit_parentheses_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::PinnedExpressionNode).void }
      def visit_pinned_expression_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::PinnedVariableNode).void }
      def visit_pinned_variable_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::PostExecutionNode).void }
      def visit_post_execution_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::PreExecutionNode).void }
      def visit_pre_execution_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RangeNode).void }
      def visit_range_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RationalNode).void }
      def visit_rational_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RedoNode).void }
      def visit_redo_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RegularExpressionNode).void }
      def visit_regular_expression_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RequiredKeywordParameterNode).void }
      def visit_required_keyword_parameter_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RequiredParameterNode).void }
      def visit_required_parameter_node(node)
        print(node.name.to_s) # rubocop:disable Lint/RedundantStringCoercion
      end

      sig { override.params(node: Prism::RescueModifierNode).void }
      def visit_rescue_modifier_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RescueNode).void }
      def visit_rescue_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RestParameterNode).void }
      def visit_rest_parameter_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::RetryNode).void }
      def visit_retry_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::ReturnNode).void }
      def visit_return_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::SelfNode).void }
      def visit_self_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::SingletonClassNode).void }
      def visit_singleton_class_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::SourceEncodingNode).void }
      def visit_source_encoding_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::SourceFileNode).void }
      def visit_source_file_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::SourceLineNode).void }
      def visit_source_line_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::SplatNode).void }
      def visit_splat_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::StatementsNode).void }
      def visit_statements_node(node)
        node.child_nodes.each do |child|
          printt
          visit(child)
          printn
        end
      end

      sig { override.params(node: Prism::StringNode).void }
      def visit_string_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::SuperNode).void }
      def visit_super_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::SymbolNode).void }
      def visit_symbol_node(node)
        print(node.unescaped)
      end

      sig { override.params(node: Prism::TrueNode).void }
      def visit_true_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::UndefNode).void }
      def visit_undef_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::UnlessNode).void }
      def visit_unless_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::UntilNode).void }
      def visit_until_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::WhenNode).void }
      def visit_when_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::WhileNode).void }
      def visit_while_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::XStringNode).void }
      def visit_x_string_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end

      sig { override.params(node: Prism::YieldNode).void }
      def visit_yield_node(node)
        raise Error, "Not Yet Implemented node #{node.inspect}"
      end
    end
  end
end
