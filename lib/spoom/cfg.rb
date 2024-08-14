# typed: strict
# frozen_string_literal: true

require "cgi"

module Spoom
  class CFG
    extend T::Sig

    class << self
      extend T::Sig

      sig { params(node: Prism::Node).returns(CFG) }
      def from_node(node)
        builder = Builder.new
        builder.visit(node)
        builder.cfg
      end
    end

    sig { returns(BasicBlock) }
    attr_reader :root

    sig { void }
    def initialize
      @root = T.let(BasicBlock.new("0"), BasicBlock)
    end

    sig { returns(T::Array[BasicBlock]) }
    def blocks
      blocks = T.let(Set.new, T::Set[BasicBlock])
      todo = T.let([@root], T::Array[BasicBlock])
      until todo.empty?
        block = T.must(todo.shift)
        next if blocks.include?(block)

        blocks << block
        todo.concat(block.outs)
      end
      blocks.to_a
    end

    sig { returns(T::Boolean) }
    def empty?
      blocks.empty?
    end

    sig { returns(String) }
    def to_dot
      seen = T.let(Set.new, T::Set[BasicBlock])
      todo = T.let([@root], T::Array[BasicBlock])
      dot = +<<~DOT
        digraph cfg {
          graph [
            fontname = "Helvetica,Arial,sans-serif"
            fontsize = 20
          ];
      DOT
      until todo.empty?
        block = T.must(todo.shift)
        next if seen.include?(block)

        seen << block
        block.to_dot(dot)
        block.edges_out.each do |out, label|
          todo << out
          dot << "\"#{block.name}\" -> \"#{out.name}\" [label=\"#{CGI.escape_html(label)}\"];\n"
        end
      end
      dot << "}"
      dot
    end

    sig { void }
    def show_dot
      Open3.popen3("xdot -") do |stdin, _stdout, stderr, _thread|
        stdin.write(to_dot)
        stdin.close
        puts stderr.read
      end
    end

    sig { returns(String) }
    def debug
      str = String.new
      blocks.sort_by(&:name).each do |block|
        str << "#{block.name}\n"
        block.outs.sort_by(&:name).each do |out|
          str << "  -> #{out.name}\n"
        end
      end
      str
    end

    class BasicBlock
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[Prism::Node]) }
      attr_reader :instructions

      sig { returns(T::Array[[BasicBlock, T.nilable(String)]]) }
      attr_reader :edges_out

      sig { params(name: String).void }
      def initialize(name)
        @name = name
        @instructions = T.let([], T::Array[Prism::Node])
        @edges_out = T.let([], T::Array[[BasicBlock, T.nilable(String)]])
      end

      sig { params(to: BasicBlock, label: T.nilable(String)).void }
      def add_edge(to, label = nil)
        @edges_out << [to, label]
      end

      sig { returns(T::Array[BasicBlock]) }
      def outs
        @edges_out.map(&:first)
      end

      sig { params(out: String).returns(String) }
      def to_dot(out)
        out << <<~DOT
          "#{name}" [
            shape="plain",
            label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="4">
              <tr><td><b>#{CGI.escapeHTML(name)}</b></td></tr>
              <tr>
                <td>#{@instructions.map(&:slice).join("<br/>")}</td>
              </tr>
            </table>>
          ]
        DOT
      end

      sig { params(other: BasicObject).returns(T::Boolean) }
      def ==(other)
        BasicBlock === other && name == other.name
      end

      sig { returns(String) }
      def to_s
        name
      end
    end

    class Scope
      extend T::Sig

      sig { returns(BasicBlock) }
      attr_reader :root, :exit

      sig { params(root: BasicBlock, exit: BasicBlock).void }
      def initialize(root:, exit:)
        @root = root
        @exit = exit
      end
    end

    class Builder < Visitor
      extend T::Sig

      sig { returns(CFG) }
      attr_reader :cfg

      sig { void }
      def initialize
        super

        @cfg = T.let(CFG.new, CFG)
        @current_block = T.let(@cfg.root, BasicBlock)
        @block_count = T.let(1, Integer)

        @scope_stack = T.let([], T::Array[Scope])
      end

      sig { params(nodes: T::Array[Prism::Node]).void }
      def visit_all(nodes)
        nodes.each do |stmt|
          visit(stmt)
          case stmt
          when Prism::BreakNode,
                Prism::CaseNode,
                Prism::DefNode,
                Prism::ForNode,
                Prism::NextNode,
                Prism::ProgramNode,
                Prism::IfNode,
                Prism::ReturnNode,
                Prism::StatementsNode,
                Prism::UnlessNode,
                Prism::UntilNode,
                Prism::WhileNode
            # we do not store these nodes as instructions
          else
            @current_block.instructions << stmt
          end
        end
      end

      sig { override.params(node: Prism::ProgramNode).void }
      def visit_program_node(node)
        super

        # add an edge from the last block to the sync block
        # T.must(@cfg.blocks.last).add_edge(new_block, "exit")
      end

      sig { override.params(node: Prism::StatementsNode).void }
      def visit_statements_node(node)
        visit_all(node.body)
      end

      sig { override.params(node: Prism::BlockNode).void }
      def visit_block_node(node)
        # puts "visit_block_node: #{node}"
        # TODO: handle blocks
      end

      sig { override.params(node: Prism::BreakNode).void }
      def visit_break_node(node)
        current_loop = @scope_stack.last
        raise Error, "Unexpected break outside of loop" unless current_loop

        current_block = @current_block
        current_block.add_edge(current_loop.exit, "break")
        after_block = new_block
        current_block.add_edge(after_block, "")
        @current_block = after_block
      end

      sig { override.params(node: Prism::CaseNode).void }
      def visit_case_node(node)
        current_block = @current_block
        merge_block = new_block

        # visit `when <predicate> <statements>`
        node.conditions.each do |condition|
          raise Error, "Unexpected #{condition}" unless condition.is_a?(Prism::WhenNode)

          case_block = new_block
          current_block = @current_block
          current_block.add_edge(case_block, "case #{node.predicate&.slice}")
          @current_block = case_block
          visit(condition.statements)
          @current_block.add_edge(merge_block, "")
        end

        # visit `else <statements>`
        if node.consequent
          else_block = new_block
          current_block.add_edge(else_block, "else")
          @current_block = else_block
          visit(node.consequent)
          @current_block.add_edge(merge_block, "")
        else
          current_block.add_edge(merge_block, "")
        end

        @current_block = merge_block
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        current_block = @current_block

        body_block = new_block
        exit_block = new_block
        current_block.add_edge(body_block, "def #{node.name}")
        @current_block = body_block

        # after_block = new_block
        # enter_block = new_block

        # @current_block.add_edge(enter_block, "def #{node.name}")
        # @current_block = enter_block

        @scope_stack << Scope.new(root: @current_block, exit: exit_block)
        @current_block = body_block
        visit(node.body)
        @current_block = current_block
        @scope_stack.pop

        body_block.add_edge(exit_block, "exit")
        @current_block = exit_block

        # exit_block.add_edge(after_block, "exit")
        # @current_block = after_block
        # @current_block.add_edge(exit_block, "exit")
      end

      sig { override.params(node: Prism::ForNode).void }
      def visit_for_node(node)
        merge_block = new_block
        @current_block.add_edge(merge_block, "")

        do_block = new_block
        @current_block.add_edge(do_block, "for #{node.index.slice} in #{node.collection.slice}")
        @current_block = do_block
        @scope_stack << Scope.new(root: do_block, exit: merge_block)
        visit(node.statements)
        @scope_stack.pop
        @current_block.add_edge(do_block, "for #{node.index.slice} in #{node.collection.slice}")
        @current_block.add_edge(merge_block, "")

        @current_block = merge_block
      end

      sig { override.params(node: Prism::NextNode).void }
      def visit_next_node(node)
        current_loop = @scope_stack.last
        raise Error, "Unexpected break outside of loop" unless current_loop

        current_block = @current_block
        current_block.add_edge(current_loop.root, "next")
        after_block = new_block
        current_block.add_edge(after_block, "")
        @current_block = after_block
      end

      sig { override.params(node: Prism::IfNode).void }
      def visit_if_node(node)
        current_block = @current_block
        merge_block = new_block

        # visit `if predicate <statements>`
        if node.statements
          then_block = new_block
          current_block = @current_block
          current_block.add_edge(then_block, "if #{node.predicate.slice}")
          @current_block = then_block
          visit(node.statements)
          @current_block.add_edge(merge_block, "")
        end

        # visit `if predicate else <statements>`
        if node.consequent
          else_block = new_block
          current_block.add_edge(else_block, "else")
          @current_block = else_block
          visit(node.consequent)
          @current_block.add_edge(merge_block, "")
        else
          current_block.add_edge(merge_block, "")
        end

        @current_block = merge_block
      end

      sig { override.params(node: Prism::ReturnNode).void }
      def visit_return_node(node)
        current_def = @scope_stack.last
        raise Error, "Unexpected return outside of def" unless current_def

        current_block = @current_block
        current_block.add_edge(current_def.exit, "exit")

        node.arguments&.arguments&.each do |arg|
          return_block = new_block
          current_block.add_edge(return_block, "return")
          @current_block = return_block
          visit(arg)
          return_block.add_edge(current_def.exit, "exit")
        end
        @current_block = current_block

        after_block = new_block
        @current_block = after_block
      end

      sig { override.params(node: Prism::UnlessNode).void }
      def visit_unless_node(node)
        current_block = @current_block
        merge_block = new_block

        # visit `unless predicate <statements>`
        if node.statements
          then_block = new_block
          current_block = @current_block
          current_block.add_edge(then_block, "unless #{node.predicate.slice}")
          @current_block = then_block
          visit(node.statements)
          @current_block.add_edge(merge_block, "merge")
        end

        # visit `unless predicate else <statements>`
        if node.consequent
          else_block = new_block
          current_block.add_edge(else_block, "else")
          @current_block = else_block
          visit(node.consequent)
          @current_block.add_edge(merge_block, "merge")
        else
          current_block.add_edge(merge_block, "merge")
        end

        @current_block = merge_block
      end

      sig { override.params(node: Prism::UntilNode).void }
      def visit_until_node(node)
        merge_block = new_block
        @current_block.add_edge(merge_block, "")

        then_block = new_block
        @current_block.add_edge(then_block, "until #{node.predicate.slice}")
        @current_block = then_block
        @scope_stack << Scope.new(root: then_block, exit: merge_block)
        visit(node.statements)
        @scope_stack.pop
        @current_block.add_edge(then_block, "until #{node.predicate.slice}")
        @current_block.add_edge(merge_block, "merge until")

        @current_block = merge_block
      end

      sig { override.params(node: Prism::WhileNode).void }
      def visit_while_node(node)
        merge_block = new_block

        then_block = new_block
        @current_block.add_edge(then_block, "until #{node.predicate.slice}")
        @current_block = then_block
        visit(node.statements)
        @current_block.add_edge(then_block, "until #{node.predicate.slice}")
        @current_block.add_edge(merge_block, "merge until")

        @current_block = merge_block
      end

      private

      sig { returns(BasicBlock) }
      def new_block
        block = BasicBlock.new(@block_count.to_s)
        @block_count += 1
        block
      end
    end
  end
end
