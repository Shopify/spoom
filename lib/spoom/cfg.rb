# typed: strict
# frozen_string_literal: true

require "cgi"

module Spoom
  class CFG
    extend T::Sig

    class << self
      extend T::Sig

      sig { params(file: String, node: Prism::Node).returns(CFG) }
      def from_node(file, node)
        builder = Builder.new(file)
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

      sig { returns(T::Boolean) }
      attr_accessor :returns

      sig { params(name: String).void }
      def initialize(name)
        @name = name
        @instructions = T.let([], T::Array[Prism::Node])
        @edges_out = T.let([], T::Array[[BasicBlock, T.nilable(String)]])
        @returns = T.let(false, T::Boolean)
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
        instructions = @instructions.map do |i|
          text = i.slice
          text = "#{text[0..50]}..." if text.size > 50
          CGI.escapeHTML(text)
        end
        out << <<~DOT
          "#{name}" [
            shape="plain",
            label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="4">
              <tr><td><b>#{CGI.escapeHTML(name)}</b></td></tr>
              <tr>
                <td>#{instructions.join("<br/>")}</td>
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

      sig { params(file: String).void }
      def initialize(file)
        super()

        @file = file

        @cfg = T.let(CFG.new, CFG)
        @current_block = T.let(@cfg.root, BasicBlock)
        @block_count = T.let(1, Integer)

        @loop_stack = T.let([], T::Array[BasicBlock])
        @scope_stack = T.let([], T::Array[Scope])
      end

      sig { override.params(node: Prism::ProgramNode).void }
      def visit_program_node(node)
        super

        # add an edge from the last block to the sync block
        # T.must(@cfg.blocks.last).add_edge(new_block, "exit")
      end

      sig { override.params(node: Prism::AndNode).void }
      def visit_and_node(node)
        left_block = new_block
        @current_block.add_edge(left_block, "and")
        @current_block = left_block
        visit(node.left)

        right_block = new_block
        @current_block.add_edge(right_block, "true")
        @current_block = right_block
        visit(node.right)

        merge_block = new_block
        left_block.add_edge(merge_block, "false") unless left_block.returns
        right_block.add_edge(merge_block, "merge") unless right_block.returns
        @current_block = merge_block
      end

      sig { override.params(node: Prism::BlockNode).void }
      def visit_block_node(node)
        puts "visit_block_node"
        super
      end

      sig { override.params(node: Prism::BreakNode).void }
      def visit_break_node(node)
        @current_block.instructions << node

        current_loop = @loop_stack.last
        raise Typecheck::Error.new(
          "Unexpected break outside of loop",
          Location.from_prism(@file, node.location),
        ) unless current_loop
      end

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        @current_block.instructions << node

        block_node = node.block

        if block_node
          block_block = new_block
          @loop_stack << block_block
          @current_block.add_edge(block_block, "block call")
          @current_block = block_block
          puts "block_node##{block_block}"
          visit(block_node)
          merge_block = new_block
          @current_block.add_edge(merge_block, "merge call")
          @current_block = merge_block
          @loop_stack.pop
        end
      end

      sig { override.params(node: Prism::CaseNode).void }
      def visit_case_node(node)
        predicate_block = new_block
        @current_block.add_edge(predicate_block, "case")
        @current_block = predicate_block
        visit(node.predicate)
        predicate_block = @current_block

        merge_block = new_block

        # visit `when <predicate> <statements>`
        node.conditions.each do |condition|
          raise Error, "Unexpected #{condition}" unless condition.is_a?(Prism::WhenNode)

          when_block = new_block
          predicate_block.add_edge(when_block, "when")
          @current_block = when_block
          visit(condition.statements)
          when_block = @current_block

          when_block.add_edge(merge_block, "merge") unless when_block.returns
        end

        # visit `else <statements>`
        else_block = new_block
        predicate_block.add_edge(else_block, "else")
        @current_block = else_block
        visit(node.consequent)
        else_block = @current_block
        else_block.add_edge(merge_block, "merge")

        @current_block = merge_block
      end

      # sig { override.params(node: Prism::DefNode).void }
      # def visit_def_node(node)
      #   current_block = @current_block

      #   body_block = new_block
      #   exit_block = new_block
      #   current_block.add_edge(body_block, "def #{node.name}")
      #   @current_block = body_block

      #   # after_block = new_block
      #   # enter_block = new_block

      #   # @current_block.add_edge(enter_block, "def #{node.name}")
      #   # @current_block = enter_block

      #   @scope_stack << Scope.new(root: @current_block, exit: exit_block)
      #   @current_block = body_block
      #   visit(node.body)
      #   @current_block = current_block
      #   @scope_stack.pop

      #   body_block.add_edge(exit_block, "exit")
      #   @current_block = exit_block

      #   # exit_block.add_edge(after_block, "exit")
      #   # @current_block = after_block
      #   # @current_block.add_edge(exit_block, "exit")
      # end

      # sig { override.params(node: Prism::ForNode).void }
      # def visit_for_node(node)
      #   merge_block = new_block
      #   @current_block.add_edge(merge_block, "")

      #   do_block = new_block
      #   @current_block.add_edge(do_block, "for #{node.index.slice} in #{node.collection.slice}")
      #   @current_block = do_block
      #   @scope_stack << Scope.new(root: do_block, exit: merge_block)
      #   visit(node.statements)
      #   @scope_stack.pop
      #   @current_block.add_edge(do_block, "for #{node.index.slice} in #{node.collection.slice}")
      #   @current_block.add_edge(merge_block, "")

      #   @current_block = merge_block
      # end

      sig { override.params(node: Prism::NextNode).void }
      def visit_next_node(node)
        @current_block.instructions << node

        current_loop = @loop_stack.last
        raise Error, "Unexpected next outside of loop" unless current_loop

        @current_block.add_edge(current_loop, "next")
        @current_block.returns = true
      end

      sig { override.params(node: Prism::IfNode).void }
      def visit_if_node(node)
        predicate_block = new_block
        @current_block.add_edge(predicate_block, "predicate")
        @current_block = predicate_block
        visit(node.predicate)
        predicate_block = @current_block

        # visit `if predicate <statements>`
        if_block = new_block
        predicate_block.add_edge(if_block, "true")
        @current_block = if_block
        visit(node.statements)
        if_block = @current_block

        # visit `if predicate else <statements>`
        else_block = new_block
        predicate_block.add_edge(else_block, "false")
        @current_block = else_block
        visit(node.consequent)
        else_block = @current_block

        merge_block = new_block
        if_block.add_edge(merge_block, "merge") unless if_block.returns
        else_block.add_edge(merge_block, "merge") unless else_block.returns
        @current_block = merge_block
      end

      sig { override.params(node: Prism::LocalVariableReadNode).void }
      def visit_local_variable_read_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::LocalVariableWriteNode).void }
      def visit_local_variable_write_node(node)
        @current_block.instructions << node
        super
      end

      sig { override.params(node: Prism::OrNode).void }
      def visit_or_node(node)
        left_block = new_block
        @current_block.add_edge(left_block, "or")
        @current_block = left_block
        visit(node.left)

        right_block = new_block
        left_block.add_edge(right_block, "true")
        @current_block = right_block
        visit(node.right)

        merge_block = new_block
        right_block.add_edge(merge_block, "merge") unless right_block.returns
        @current_block = merge_block
      end

      sig { override.params(node: Prism::ReturnNode).void }
      def visit_return_node(node)
        @current_block.instructions << node
        @current_block.returns = true
      end

      sig { override.params(node: Prism::UnlessNode).void }
      def visit_unless_node(node)
        predicate_block = new_block
        @current_block.add_edge(predicate_block, "unless")
        @current_block = predicate_block
        visit(node.predicate)
        predicate_block = @current_block

        # visit `unless predicate <statements>`
        unless_block = new_block
        predicate_block.add_edge(unless_block, "true")
        @current_block = unless_block
        visit(node.statements)
        unless_block = @current_block

        # visit `if predicate else <statements>`
        else_block = new_block
        predicate_block.add_edge(else_block, "false")
        @current_block = else_block
        visit(node.consequent)
        else_block = @current_block

        merge_block = new_block
        unless_block.add_edge(merge_block, "merge") unless unless_block.returns
        else_block.add_edge(merge_block, "merge") unless else_block.returns
        @current_block = merge_block
      end

      sig { override.params(node: Prism::UntilNode).void }
      def visit_until_node(node)
        predicate_block = new_block
        @current_block.add_edge(predicate_block, "until")
        @current_block = predicate_block
        visit(node.predicate)

        # visit `until predicate <statements>`
        then_block = nil
        if node.statements
          @loop_stack << predicate_block
          then_block = new_block
          predicate_block.add_edge(then_block, "true")
          @current_block = then_block
          visit(node.statements)
          then_block = @current_block
          @loop_stack.pop
        end

        merge_block = new_block
        predicate_block.add_edge(merge_block, "false")
        then_block.add_edge(merge_block, "merge true") if then_block && !then_block.returns
        @current_block = merge_block
      end

      sig { override.params(node: Prism::WhileNode).void }
      def visit_while_node(node)
        predicate_block = new_block
        @current_block.add_edge(predicate_block, "while")
        @current_block = predicate_block
        visit(node.predicate)

        # visit `until predicate <statements>`
        then_block = nil
        if node.statements
          @loop_stack << predicate_block
          then_block = new_block
          predicate_block.add_edge(then_block, "true")
          @current_block = then_block
          visit(node.statements)
          then_block = @current_block
          @loop_stack.pop
        end

        merge_block = new_block
        predicate_block.add_edge(merge_block, "false")
        then_block.add_edge(merge_block, "merge true") if then_block && !then_block.returns
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
