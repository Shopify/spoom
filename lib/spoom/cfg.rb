# typed: strict
# frozen_string_literal: true

require "cgi"

module Spoom
  class CFG
    extend T::Sig

    class << self
      extend T::Sig

      sig { params(node: Prism::Node).returns(Cluster) }
      def from_node(node)
        # puts node.inspect
        walker = Walker.new
        walker.visit(node)
        walker.cluster
      end
    end

    class Error < Spoom::Error
      extend T::Sig

      sig { params(message: String, node: Prism::Node).void }
      def initialize(message, node)
        super(message)

        @node = node
      end
    end

    class Cluster
      extend T::Sig

      sig { returns(T::Array[CFG]) }
      attr_reader :cfgs

      sig { void }
      def initialize
        @cfgs = T.let([], T::Array[CFG])
      end

      sig { returns(T.self_type) }
      def compact!
        @cfgs.each(&:compact!)
        self
      end

      sig { returns(String) }
      def to_dot
        dot = +""
        dot << "digraph cfg {\n"
        cfgs.each do |cfg|
          dot << cfg.to_dot(subgraph: true)
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

      sig { override.returns(String) }
      def inspect
        @cfgs.map(&:inspect).join("\n")
      end
    end

    class BasicBlock
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[Prism::Node]) }
      attr_reader :instructions

      sig { returns(T::Array[BasicBlock]) }
      attr_reader :ins

      sig { returns(T::Array[BasicBlock]) }
      attr_reader :outs

      sig { returns(T::Boolean) }
      attr_accessor :exits

      sig { params(name: String).void }
      def initialize(name)
        @name = name
        @instructions = T.let([], T::Array[Prism::Node])
        @ins = T.let([], T::Array[BasicBlock])
        @outs = T.let([], T::Array[BasicBlock])
        @exits = T.let(false, T::Boolean)
      end

      sig { returns(T::Boolean) }
      def empty?
        @instructions.empty?
      end

      sig { params(to: BasicBlock).void }
      def add_edge(to)
        @outs << to
        to.ins << self
      end

      sig { returns(String) }
      def to_s
        name
      end

      sig { params(cluster_id: String).returns(String) }
      def to_dot(cluster_id)
        instructions = @instructions.map do |i|
          text = case i
          when Prism::ClassNode
            "class #{i.name}"
          when Prism::ModuleNode
            "module #{i.name}"
          when Prism::SingletonClassNode
            "class << self"
          when Prism::DefNode
            "def #{i.name}"
          when Prism::CallNode
            "#{i.receiver&.slice || "<self>"}.#{i.name}(#{i.arguments&.slice})"
          when Prism::BlockNode
            "<block-call>"
          when Prism::BeginNode
            "<begin>"
          else
            i.slice
          end
          text = text.gsub(/\n+/, "; ").gsub(/\s+/, " ")
          text = "#{text[0..50]}..." if text.size > 50
          CGI.escapeHTML(text)
        end
        dot = +<<~DOT
          "#{cluster_id}#{name}" [
            shape="plain",
            label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="4">
              <tr><td><b>#{CGI.escapeHTML(name)}</b></td></tr>
              <tr>
                <td>#{instructions.join("<br/>")}</td>
              </tr>
            </table>>
          ]
        DOT
        @outs.each do |out|
          dot << "\"#{cluster_id}#{name}\" -> \"#{cluster_id}#{out.name}\";\n"
        end
        dot
      end

      sig { override.returns(String) }
      def inspect
        out = +"  bb##{@name}\n"
        @instructions.each do |i|
          text = case i
          when Prism::ClassNode
            "class #{i.name}"
          when Prism::ModuleNode
            "module #{i.name}"
          when Prism::SingletonClassNode
            "class << self"
          when Prism::DefNode
            "def #{i.name}"
          when Prism::CallNode
            "#{i.receiver&.slice || "<self>"}.#{i.name}(#{i.arguments&.slice})"
          when Prism::BlockNode
            "<block-call>"
          when Prism::BeginNode
            "<begin>"
          else
            i.slice
          end
          text = text.gsub(/\n+/, "; ").gsub(/\s+/, " ")
          out << "    #{text}\n"
        end
        outs.each do |edge_out|
          out << "    -> bb##{edge_out.name}\n"
        end
        out
      end
    end

    class Loop
      extend T::Sig

      sig { returns(BasicBlock) }
      attr_reader :header

      sig { returns(BasicBlock) }
      attr_reader :merge

      sig { params(header: BasicBlock, merge: BasicBlock).void }
      def initialize(header, merge)
        @header = header
        @merge = merge
      end
    end

    class Walker < Visitor
      extend T::Sig

      sig { returns(Cluster) }
      attr_reader :cluster

      sig { void }
      def initialize
        super()

        @cluster = T.let(Cluster.new, Cluster)
      end

      sig { override.params(node: Prism::ProgramNode).void }
      def visit_program_node(node)
        builder = Builder.new("<main>", node)
        builder.visit(node.statements)
        builder.finalize!
        @cluster.cfgs << builder.cfg

        super
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        builder = Builder.new("#{node.name}::<static-init>", node)
        builder.visit(node.body)
        builder.finalize!
        @cluster.cfgs << builder.cfg

        super
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        builder = Builder.new("#{node.name}::<static-init>", node)
        builder.visit(node.body)
        builder.finalize!
        @cluster.cfgs << builder.cfg

        super
      end

      sig { override.params(node: Prism::SingletonClassNode).void }
      def visit_singleton_class_node(node)
        builder = Builder.new("class << self::<static-init>", node)
        builder.visit(node.body)
        builder.finalize!
        @cluster.cfgs << builder.cfg

        super
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        builder = Builder.new(node.name.to_s, node)
        builder.visit(node.body)
        builder.finalize!
        @cluster.cfgs << builder.cfg
      end
    end

    class Builder < Visitor
      extend T::Sig

      sig { returns(CFG) }
      attr_reader :cfg

      sig { params(name: String, node: Prism::Node).void }
      def initialize(name, node)
        super()

        @block_count = T.let(0, Integer)
        @loop_stack = T.let([], T::Array[Loop])
        @current_block = T.let(new_block, BasicBlock)
        @last_return_block = T.let(nil, T.nilable(BasicBlock))
        @exit_block = T.let(new_block, BasicBlock)
        @cfg = T.let(CFG.new(name, node, @current_block, @exit_block), CFG)
      end

      sig { void }
      def finalize!
        @current_block.add_edge(@exit_block) unless @current_block.exits
      end

      sig { override.params(node: Prism::AndNode).void }
      def visit_and_node(node)
        # We merge the left side in the current block
        visit(node.left)
        left_block = @current_block

        right_block = new_block
        @current_block.add_edge(right_block)
        @current_block = right_block
        visit(node.right)
        right_block = @current_block

        merge_block = new_block
        left_block.add_edge(merge_block) unless left_block.exits
        right_block.add_edge(merge_block) unless right_block.exits
        @current_block = merge_block
      end

      # sig { override.params(node: Prism::BlockNode).void }
      # def visit_block_node(node)
      #   super
      # end

      sig { override.params(node: Prism::BeginNode).void }
      def visit_begin_node(node)
        before_block = @current_block

        begin_block = new_block
        @current_block.add_edge(begin_block)
        @current_block = begin_block
        visit(node.statements)
        begin_block = @current_block

        rescue_blocks = T.let([], T::Array[BasicBlock])
        rescue_node = T.let(node.rescue_clause, T.nilable(Prism::RescueNode))
        while rescue_node
          rescue_block = new_block
          before_block.add_edge(rescue_block)

          @current_block = rescue_block
          visit(rescue_node)
          rescue_block = @current_block

          rescue_blocks << rescue_block
          rescue_node = rescue_node.consequent
        end

        else_node = node.else_clause
        if else_node
          else_block = new_block
          begin_block.add_edge(else_block) unless begin_block.exits
          @current_block = else_block
          visit(else_node)
          else_block = @current_block
        end

        merge_block = new_block
        ensure_node = node.ensure_clause
        if ensure_node
          ensure_block = new_block
          if else_block
            else_block.add_edge(ensure_block)
          else
            begin_block.add_edge(ensure_block) unless begin_block.exits
          end
          rescue_blocks.each do |rescue_block|
            rescue_block.add_edge(ensure_block)
          end
          @current_block = ensure_block
          visit(ensure_node)
          ensure_block = @current_block
          ensure_block.add_edge(merge_block)
        else
          if else_block
            else_block.add_edge(merge_block)
          else
            puts "begin_block.exits: #{begin_block.exits}"
            puts "begin_block#{begin_block} -> merge_block#{merge_block}"
            begin_block.add_edge(merge_block) unless begin_block.exits
          end
          rescue_blocks.each do |rescue_block|
            rescue_block.add_edge(merge_block) unless rescue_block.exits
          end
        end

        @current_block = merge_block
      end

      sig { override.params(node: Prism::BreakNode).void }
      def visit_break_node(node)
        current_loop = @loop_stack.last
        raise Error.new("Unexpected break outside of loop", node) unless current_loop

        @current_block.instructions << node
        @current_block.add_edge(current_loop.merge)

        after_block = new_block
        @current_block.add_edge(after_block)
        @current_block = after_block
        @current_block.exits = true
      end

      sig { override.params(node: Prism::CallNode).void }
      def visit_call_node(node)
        @current_block.instructions << node
        before_block = @current_block

        block_node = node.block
        if block_node
          call_block = new_block
          before_block.add_edge(call_block)
          call_block.instructions << block_node

          block_block = new_block
          call_block.add_edge(block_block)
          @current_block = block_block
          @loop_stack << Loop.new(call_block, @exit_block)
          visit(block_node)
          @loop_stack.pop
          block_block = @current_block
          block_block.add_edge(call_block) unless block_block.exits

          merge_block = new_block
          call_block.add_edge(merge_block)
          @current_block = merge_block
        end
      end

      sig { override.params(node: Prism::CaseNode).void }
      def visit_case_node(node)
        visit(node.predicate)
        before_block = @current_block

        merge_block = new_block

        node.conditions.each do |condition|
          raise Error.new("Unexpected #{condition}", node) unless condition.is_a?(Prism::WhenNode)

          when_block = new_block
          before_block.add_edge(when_block)
          @current_block = when_block
          visit(condition.statements)
          when_block = @current_block

          when_block.add_edge(merge_block) unless when_block.exits
        end

        if node.consequent
          else_block = new_block
          before_block.add_edge(else_block)
          @current_block = else_block
          visit(node.consequent)
          else_block = @current_block
          else_block.add_edge(merge_block)
        else
          before_block.add_edge(merge_block)
        end

        @current_block = merge_block
      end

      sig { override.params(node: Prism::ClassNode).void }
      def visit_class_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::DefNode).void }
      def visit_def_node(node)
        @current_block.instructions << node
      end

      # sig { override.params(node: Prism::EnsureNode).void }
      # def visit_ensure_node(node)
      #   before_block = @current_block

      #   ensure_block = new_block
      #   @current_block = ensure_block
      #   visit(node.statements)
      #   ensure_block = @current_block

      #   before_block.add_edge(ensure_block)
      #   # ensure_block.add_edge(@exit_block)

      #   merge_block = new_block
      #   ensure_block.add_edge(merge_block)
      #   @current_block = merge_block
      # end

      sig { override.params(node: Prism::FalseNode).void }
      def visit_false_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::ForNode).void }
      def visit_for_node(node)
        before_block = @current_block
        before_block.instructions << node.collection

        iterator_block = new_block
        @current_block.add_edge(iterator_block)
        @current_block = iterator_block
        visit(node.index)
        iterator_block = @current_block

        body_block = new_block
        merge_block = new_block

        if node.statements
          @loop_stack << Loop.new(iterator_block, merge_block)
          iterator_block.add_edge(body_block)
          @current_block = body_block
          visit(node.statements)
          body_block = @current_block
          body_block.add_edge(iterator_block) unless body_block.exits
          @loop_stack.pop
        end

        iterator_block.add_edge(merge_block)
        @current_block = merge_block
      end

      sig { override.params(node: Prism::NilNode).void }
      def visit_nil_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::NextNode).void }
      def visit_next_node(node)
        current_loop = @loop_stack.last
        raise Error.new("Unexpected next outside of loop", node) unless current_loop

        @current_block.instructions << node
        @current_block.add_edge(current_loop.header)

        after_block = new_block
        @current_block.add_edge(after_block)
        @current_block = after_block
        @current_block.exits = true
      end

      sig { override.params(node: Prism::IfNode).void }
      def visit_if_node(node)
        before_block = @current_block
        visit(node.predicate)

        if_block = new_block
        else_block = new_block
        merge_block = new_block

        before_block.add_edge(if_block)
        @current_block = if_block
        visit(node.statements)
        if_block = @current_block
        if_block.add_edge(merge_block) unless if_block.exits

        if node.consequent
          before_block.add_edge(else_block)
          @current_block = else_block
          visit(node.consequent)
          else_block = @current_block
          else_block.add_edge(merge_block) unless else_block.exits
        else
          before_block.add_edge(merge_block)
        end

        if if_block.exits && else_block.exits
          dead_block = new_block
          @current_block = dead_block
        else
          @current_block = merge_block
        end
      end

      sig { override.params(node: Prism::LocalVariableReadNode).void }
      def visit_local_variable_read_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::LocalVariableTargetNode).void }
      def visit_local_variable_target_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::LocalVariableWriteNode).void }
      def visit_local_variable_write_node(node)
        @current_block.instructions << node
        super
      end

      sig { override.params(node: Prism::ModuleNode).void }
      def visit_module_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::OrNode).void }
      def visit_or_node(node)
        # We merge the left side in the current block
        visit(node.left)
        left_block = @current_block

        right_block = new_block
        left_block.add_edge(right_block)
        @current_block = right_block
        visit(node.right)
        right_block = @current_block

        merge_block = new_block
        left_block.add_edge(merge_block) unless left_block.exits
        right_block.add_edge(merge_block) unless right_block.exits
        @current_block = merge_block
      end

      sig { override.params(node: Prism::RescueNode).void }
      def visit_rescue_node(node)
        visit(node.statements)
      end

      sig { override.params(node: Prism::ReturnNode).void }
      def visit_return_node(node)
        @current_block.instructions << node
        @current_block.add_edge(@exit_block)
        @last_return_block = @current_block
        dead_block = new_block
        @current_block.add_edge(dead_block)
        @current_block = dead_block
        @current_block.exits = true
      end

      sig { override.params(node: Prism::SingletonClassNode).void }
      def visit_singleton_class_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::TrueNode).void }
      def visit_true_node(node)
        @current_block.instructions << node
      end

      sig { override.params(node: Prism::UnlessNode).void }
      def visit_unless_node(node)
        before_block = @current_block
        visit(node.predicate)

        if_block = new_block
        else_block = new_block
        merge_block = new_block

        before_block.add_edge(if_block)
        @current_block = if_block
        visit(node.statements)
        if_block = @current_block
        if_block.add_edge(merge_block) unless if_block.exits

        if node.consequent
          before_block.add_edge(else_block)
          @current_block = else_block
          visit(node.consequent)
          else_block = @current_block
          else_block.add_edge(merge_block) unless else_block.exits
        else
          before_block.add_edge(merge_block)
        end

        @current_block = merge_block
      end

      sig { override.params(node: Prism::UntilNode).void }
      def visit_until_node(node)
        before_block = @current_block

        predicate_block = new_block
        before_block.add_edge(predicate_block)
        @current_block = predicate_block
        visit(node.predicate)
        predicate_block = @current_block

        body_block = new_block
        merge_block = new_block

        if node.statements
          @loop_stack << Loop.new(predicate_block, merge_block)
          predicate_block.add_edge(body_block)
          @current_block = body_block
          visit(node.statements)
          body_block = @current_block
          body_block.add_edge(predicate_block) unless body_block.exits
          @loop_stack.pop
        end

        predicate_block.add_edge(merge_block)
        @current_block = merge_block
      end

      sig { override.params(node: Prism::WhileNode).void }
      def visit_while_node(node)
        before_block = @current_block

        predicate_block = new_block
        before_block.add_edge(predicate_block)
        @current_block = predicate_block
        visit(node.predicate)
        predicate_block = @current_block

        body_block = new_block
        merge_block = new_block

        if node.statements
          @loop_stack << Loop.new(predicate_block, merge_block)
          predicate_block.add_edge(body_block)
          @current_block = body_block
          visit(node.statements)
          body_block = @current_block
          body_block.add_edge(predicate_block) unless body_block.exits
          @loop_stack.pop
        end

        predicate_block.add_edge(merge_block)
        @current_block = merge_block
      end

      sig { override.params(node: Prism::YieldNode).void }
      def visit_yield_node(node)
        @current_block.instructions << node
      end

      private

      sig { returns(BasicBlock) }
      def new_block
        block = BasicBlock.new(@block_count.to_s)
        @block_count += 1
        block
      end
    end

    sig { returns(String) }
    attr_accessor :name

    sig { returns(Prism::Node) }
    attr_reader :node

    sig { returns(BasicBlock) }
    attr_reader :root_block, :exit_block

    sig { params(name: String, node: Prism::Node, root_block: BasicBlock, exit_block: BasicBlock).void }
    def initialize(name, node, root_block, exit_block)
      @name = name
      @node = node
      @root_block = root_block
      @exit_block = exit_block
    end

    sig { returns(T::Array[BasicBlock]) }
    def blocks
      blocks = T.let([], T::Array[BasicBlock])
      queue = T.let([root_block], T::Array[BasicBlock])
      seen = T.let(Set.new, T::Set[BasicBlock])

      until queue.empty?
        block = T.must(queue.shift)
        next unless seen.add?(block)

        blocks << block
        queue.concat(block.outs)
      end

      blocks
    end

    sig { returns(T::Boolean) }
    def empty?
      blocks.empty?
    end

    sig { returns(T.self_type) }
    def compact!
      return self if blocks.size == 1

      blocks.each do |block|
        next if block == @root_block
        next if block == @exit_block
        next unless block.empty?

        block.ins.each do |block_in|
          block_in.outs.delete(block)
          block_in.outs.concat(block.outs)
        end

        block.outs.each do |block_out|
          block_out.ins.delete(block)
          block_out.ins.concat(block.ins)
        end
      end

      self
    end

    sig { params(subgraph: T::Boolean).returns(String) }
    def to_dot(subgraph: false)
      dot = +""

      cluster_id = "cluster_#{node.object_id}"

      dot << if subgraph
        <<-DOT
          subgraph "#{cluster_id}" {
            label="#{name}";
            color="blue";
        DOT
      else
        <<-DOT
          digraph cfg {
        DOT
      end
      blocks.each do |block|
        dot << block.to_dot(cluster_id)
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

    sig { override.returns(String) }
    def inspect
      out = +"cfg: #{@name}\n\n"
      out << blocks.map(&:inspect).join("\n")
      out
    end
  end
end
