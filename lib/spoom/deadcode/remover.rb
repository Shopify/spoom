# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Remover
      extend T::Sig

      class Error < Spoom::Error; end

      sig { params(context: Context).void }
      def initialize(context)
        @context = context
      end

      sig { params(kind: Definition::Kind, location: Location).void }
      def remove_location(kind, location)
        file = location.file

        unless @context.file?(file)
          raise Error, "Can't find file at #{file}"
        end

        node_remover = NodeRemover.new(@context.read(file), kind, location)
        node_remover.apply_edit
        @context.write!(file, node_remover.new_source)
      end

      class NodeRemover
        extend T::Sig

        sig { returns(String) }
        attr_reader :new_source

        sig { params(source: String, kind: Definition::Kind, location: Location).void }
        def initialize(source, kind, location)
          @old_source = source
          @new_source = T.let(source.dup, String)
          @kind = kind
          @location = location

          @node_context = T.let(NodeFinder.find(source, location, kind), NodeContext)
        end

        sig { void }
        def apply_edit
          sclass_context = @node_context.sclass_context
          if sclass_context
            delete_node_and_comments_and_sigs(sclass_context)
            return
          end

          node = @node_context.node
          case node
          when SyntaxTree::ClassDeclaration, SyntaxTree::ModuleDeclaration, SyntaxTree::DefNode
            delete_node_and_comments_and_sigs(@node_context)
          when SyntaxTree::Const, SyntaxTree::ConstPathField
            delete_constant_assignment(@node_context)
          when SyntaxTree::SymbolLiteral # for attr accessors
            delete_attr_accessor(@node_context)
          else
            raise Error, "Unsupported node type: #{node.class}"
          end
        end

        private

        sig { params(context: NodeContext).void }
        def delete_constant_assignment(context)
          # Pop the Varfield node from the nesting nodes
          if context.node.is_a?(SyntaxTree::Const)
            context = context.parent_context
          end

          parent_context = context.parent_context
          parent_node = parent_context.node
          if parent_node.is_a?(SyntaxTree::Assign)
            # Nesting node is an assign, it means only one constant is assigned on the line
            # so we can remove the whole assign
            delete_node_and_comments_and_sigs(parent_context)
            return
          elsif parent_node.is_a?(SyntaxTree::MLHS) && parent_node.parts.size == 1
            # Nesting node is a single left hand side, it means only one constant is assigned
            # so we can remove the whole line
            delete_node_and_comments_and_sigs(parent_context.parent_context)
            return
          end

          # Nesting node is a multiple left hand side, it means multiple constants are assigned
          # so we need to remove only the right node from the left hand side
          node = context.node
          prev_node = context.previous_node
          next_node = context.next_node

          if (prev_node && prev_node.location.end_line != node.location.start_line) &&
              (next_node && next_node.location.start_line != node.location.end_line)
            # We have a node before and after, but on different lines, we need to remove the whole line
            #
            # ~~~
            # FOO,
            # BAR, # we need to remove BAR
            # BAZ = 42
            # ~~~
            delete_lines(node.location.start_line, node.location.end_line)
          elsif prev_node && next_node
            # We have a node before and after one the same line, just remove the part of the line
            #
            # ~~~
            # FOO, BAR, BAZ = 42 # we need to remove BAR
            # ~~~
            replace_chars(prev_node.location.end_char, next_node.location.start_char, ", ")
          elsif prev_node
            # We have a node before, on the same line, but no node after, just remove the part of the line
            #
            # ~~~
            # FOO, BAR = 42 # we need to remove BAR
            # ~~~
            nesting_context = parent_context.parent_context
            nesting_assign = T.cast(nesting_context.node, T.any(SyntaxTree::MAssign, SyntaxTree::MLHSParen))
            case nesting_assign
            when SyntaxTree::MAssign
              replace_chars(prev_node.location.end_char, nesting_assign.value.location.start_char, " = ")
            when SyntaxTree::MLHSParen
              nesting_context = nesting_context.parent_context
              nesting_assign = T.cast(nesting_context.node, SyntaxTree::MAssign)
              replace_chars(prev_node.location.end_char, nesting_assign.value.location.start_char, ") = ")
            end
          elsif next_node
            # We don't have a node before but a node after on the same line, just remove the part of the line
            #
            # ~~~
            # FOO, BAR = 42 # we need to remove FOO
            # ~~~
            delete_chars(node.location.start_char, next_node.location.start_char)
          else
            # Should have been removed as a single MLHS node
            raise "Unexpected case while removing constant assignment"
          end
        end

        sig { params(context: NodeContext).void }
        def delete_attr_accessor(context)
          args_context = context.parent_context
          send_context = args_context.parent_context
          send_context = send_context.parent_context if send_context.node.is_a?(SyntaxTree::ArgParen)

          send_node = T.cast(send_context.node, T.any(SyntaxTree::Command, SyntaxTree::CallNode))
          need_accessor = context.node_string(send_node.message) == "attr_accessor"

          if args_context.node.child_nodes.size == 1
            # Only one accessor is defined, we can remove the whole node
            delete_node_and_comments_and_sigs(send_context)
            insert_accessor(context.node, send_context, was_removed: true) if need_accessor
            return
          end

          prev_node = context.previous_node
          next_node = context.next_node

          if (prev_node && prev_node.location.end_line != context.node.location.start_line) &&
              (next_node && next_node.location.start_line != context.node.location.end_line)
            # We have a node before and after, but on different lines, we need to remove the whole line
            #
            # ~~~
            # attr_reader(
            #  :foo,
            #  :bar, # attr to remove
            #  :baz,
            # )
            # ~~~
            delete_lines(context.node.location.start_line, context.node.location.end_line)
          elsif prev_node && next_node
            # We have a node before and after one the same line, just remove the part of the line
            #
            # ~~~
            # attr_reader :foo, :bar, :baz # we need to remove bar
            # ~~~
            replace_chars(prev_node.location.end_char, next_node.location.start_char, ", ")
          elsif prev_node
            # We have a node before, on the same line, but no node after, just remove the part of the line
            #
            # ~~~
            # attr_reader :foo, :bar, :baz # we need to remove baz
            # ~~~
            delete_chars(prev_node.location.end_char, context.node.location.end_char)
          elsif next_node
            # We don't have a node before but a node after on the same line, just remove the part of the line
            #
            # ~~~
            # attr_reader :foo, :bar, :baz # we need to remove foo
            # ~~~
            delete_chars(context.node.location.start_char, next_node.location.start_char)
          else
            raise "Unexpected case while removing attr_accessor"
          end

          insert_accessor(context.node, send_context, was_removed: false) if need_accessor
        end

        sig do
          params(
            node: SyntaxTree::Node,
            send_context: NodeContext,
            was_removed: T::Boolean,
          ).void
        end
        def insert_accessor(node, send_context, was_removed:)
          name = @node_context.node_string(node)
          code = case @kind
          when Definition::Kind::AttrReader
            "attr_writer #{name}"
          when Definition::Kind::AttrWriter
            "attr_reader #{name}"
          end

          indent = " " * send_context.node.location.start_column

          sig = send_context.attached_sig
          sig_string = transform_sig(sig, name: name, kind: @kind) if sig

          node_after = send_context.next_node

          if was_removed
            first_node = send_context.attached_comments_and_sigs.first || send_context.node
            at_line = first_node.location.start_line - 1

            prev_context = NodeContext.new(@old_source, first_node, send_context.nesting)
            node_before = prev_context.previous_node

            new_line_before = node_before && send_context.node.location.start_line - node_before.location.end_line < 2
            new_line_after = node_after && node_after.location.start_line - send_context.node.location.end_line <= 2
          else
            at_line = send_context.node.location.end_line
            new_line_before = true
            new_line_after = node_after && node_after.location.start_line - send_context.node.location.end_line < 2
          end

          lines_to_insert = String.new
          lines_to_insert << "\n" if new_line_before
          lines_to_insert << "#{indent}#{sig_string}\n" if sig_string
          lines_to_insert << "#{indent}#{code}\n"
          lines_to_insert << "\n" if new_line_after

          lines = @new_source.lines
          lines.insert(at_line, lines_to_insert)
          @new_source = lines.join
        end

        sig { params(context: NodeContext).void }
        def delete_node_and_comments_and_sigs(context)
          start_line = context.node.location.start_line
          end_line = context.node.location.end_line

          # Adjust the lines to remove to include the comments
          nodes = context.attached_comments_and_sigs
          if nodes.any?
            start_line = T.must(nodes.first).location.start_line
          end

          # Adjust the lines to remove to include previous blank lines
          prev_context = NodeContext.new(@old_source, nodes.first || context.node, context.nesting)
          before = prev_context.previous_node
          if before && before.location.end_line < start_line - 1
            # There is a node before and a blank line
            start_line = before.location.end_line + 1
          elsif before.nil? && context.parent_node.location.start_line < start_line - 1
            # There is no node before, but a blank line
            start_line = context.parent_node.location.start_line + 1
          end

          # Adjust the lines to remove to include following blank lines
          after = context.next_node
          if before.nil? && after && after.location.start_line > end_line + 1
            end_line = after.location.end_line - 1
          elsif after.nil? && context.parent_node.location.end_line > end_line + 1
            end_line = context.parent_node.location.end_line - 1
          end

          delete_lines(start_line, end_line)
        end

        sig { params(start_line: Integer, end_line: Integer).void }
        def delete_lines(start_line, end_line)
          lines = @new_source.lines
          lines[start_line - 1...end_line] = []
          @new_source = lines.join
        end

        sig { params(start_char: Integer, end_char: Integer).void }
        def delete_chars(start_char, end_char)
          @new_source[start_char...end_char] = ""
        end

        sig { params(start_char: Integer, end_char: Integer, replacement: String).void }
        def replace_chars(start_char, end_char, replacement)
          @new_source[start_char...end_char] = replacement
        end

        sig { params(line_number: Integer, start_column: Integer, end_column: Integer).void }
        def delete_line_part(line_number, start_column, end_column)
          lines = []
          @new_source.lines.each_with_index do |line, index|
            current_line = index + 1

            lines << if line_number == current_line
              T.must(line[0...start_column]) + T.must(line[end_column..-1])
            else
              line
            end
          end
          @new_source = lines.join
        end

        sig { params(node: SyntaxTree::MethodAddBlock, name: String, kind: Definition::Kind).returns(String) }
        def transform_sig(node, name:, kind:)
          type = T.let(nil, T.nilable(String))

          statements = node.block.bodystmt
          statements = statements.statements if statements.is_a?(SyntaxTree::BodyStmt)

          statements.body.each do |call|
            next unless call.is_a?(SyntaxTree::CallNode)
            next unless @node_context.node_string(call.message) == "returns"

            args = call.arguments
            args = args.arguments if args.is_a?(SyntaxTree::ArgParen)

            next unless args.is_a?(SyntaxTree::Args)

            first = args.parts.first
            next unless first

            type = @node_context.node_string(first)
          end

          name = name.delete_prefix(":")
          type = T.must(type)

          case kind
          when Definition::Kind::AttrReader
            "sig { params(#{name}: #{type}).returns(#{type}) }"
          else
            "sig { returns(#{type}) }"
          end
        end
      end

      class NodeContext
        extend T::Sig

        sig { returns(SyntaxTree::Node) }
        attr_reader :node

        sig { returns(T::Array[SyntaxTree::Node]) }
        attr_accessor :nesting

        sig { params(source: String, node: SyntaxTree::Node, nesting: T::Array[SyntaxTree::Node]).void }
        def initialize(source, node, nesting)
          @source = source
          @node = node
          @nesting = nesting
        end

        sig { returns(SyntaxTree::Node) }
        def parent_node
          parent = @nesting.last
          raise "No parent for node #{node}" unless parent

          parent
        end

        sig { returns(NodeContext) }
        def parent_context
          nesting = @nesting.dup
          parent = nesting.pop
          raise "No parent context for node #{@node}" unless parent

          NodeContext.new(@source, parent, nesting)
        end

        sig { returns(T::Array[SyntaxTree::Node]) }
        def previous_nodes
          parent = parent_node

          index = parent.child_nodes.index(@node)
          raise "Node #{@node} not found in parent #{parent}" unless index

          parent.child_nodes[0...index].reject { |child| child.is_a?(SyntaxTree::VoidStmt) }
        end

        sig { returns(T.nilable(SyntaxTree::Node)) }
        def previous_node
          previous_nodes.last
        end

        sig { returns(T::Array[SyntaxTree::Node]) }
        def next_nodes
          parent = parent_node

          index = parent.child_nodes.index(node)
          raise "Node #{@node} not found in nesting node #{parent}" unless index

          parent.child_nodes[(index + 1)..-1].reject { |node| node.is_a?(SyntaxTree::VoidStmt) }
        end

        sig { returns(T.nilable(SyntaxTree::Node)) }
        def next_node
          next_nodes.first
        end

        sig { returns(T.nilable(NodeContext)) }
        def sclass_context
          sclass = T.let(nil, T.nilable(SyntaxTree::SClass))

          nesting = @nesting.dup
          until nesting.empty? || sclass
            node = nesting.pop
            next unless node.is_a?(SyntaxTree::SClass)

            sclass = node
          end

          return unless sclass.is_a?(SyntaxTree::SClass)

          nodes = sclass.bodystmt.statements.body.reject do |node|
            node.is_a?(SyntaxTree::VoidStmt) || node.is_a?(SyntaxTree::Comment) ||
              sorbet_signature?(node) || sorbet_extend_sig?(node)
          end

          if nodes.size <= 1
            return NodeContext.new(@source, sclass, nesting)
          end

          nil
        end

        sig { params(node: T.nilable(SyntaxTree::Node)).returns(T::Boolean) }
        def sorbet_signature?(node)
          return false unless node.is_a?(SyntaxTree::MethodAddBlock)

          call = node.call
          return false unless call.is_a?(SyntaxTree::CallNode)

          ident = call.message
          return false unless ident.is_a?(SyntaxTree::Ident)

          ident.value == "sig"
        end

        sig { params(node: T.nilable(SyntaxTree::Node)).returns(T::Boolean) }
        def sorbet_extend_sig?(node)
          return false unless node.is_a?(SyntaxTree::Command)
          return false unless node_string(node.message) == "extend"
          return false unless node.arguments.parts.size == 1

          node_string(T.must(node.arguments.parts.first)) == "T::Sig"
        end

        sig { params(comment: SyntaxTree::Node, node: SyntaxTree::Node).returns(T::Boolean) }
        def comment_for_node?(comment, node)
          return false unless comment.is_a?(SyntaxTree::Comment)

          comment.location.end_line == node.location.start_line - 1
        end

        sig { returns(T::Array[SyntaxTree::Node]) }
        def attached_comments_and_sigs
          nodes = T.let([], T::Array[SyntaxTree::Node])

          previous_nodes.reverse_each do |prev_node|
            break unless comment_for_node?(prev_node, nodes.last || node) || sorbet_signature?(prev_node)

            nodes << prev_node
          end

          nodes.reverse
        end

        sig { returns(T.nilable(SyntaxTree::MethodAddBlock)) }
        def attached_sig
          previous_nodes.reverse_each do |node|
            if node.is_a?(SyntaxTree::Comment)
              next
            elsif sorbet_signature?(node)
              return T.cast(node, SyntaxTree::MethodAddBlock)
            else
              break
            end
          end

          nil
        end

        sig { params(node: T.any(Symbol, SyntaxTree::Node)).returns(String) }
        def node_string(node)
          case node
          when Symbol
            node.to_s
          else
            T.must(@source[node.location.start_char...node.location.end_char])
          end
        end
      end

      class NodeFinder < SyntaxTree::Visitor
        extend T::Sig

        class << self
          extend T::Sig

          sig { params(source: String, location: Location, kind: Definition::Kind).returns(NodeContext) }
          def find(source, location, kind)
            tree = SyntaxTree.parse(source)

            visitor = new(location)
            visitor.visit(tree)

            node = visitor.node
            unless node
              raise Error, "Can't find node at #{location}"
            end

            unless node_match_kind?(node, kind)
              raise Error, "Can't find node at #{location}, expected #{kind} but got #{node.class}"
            end

            NodeContext.new(source, node, visitor.nodes_nesting)
          end

          sig { params(node: SyntaxTree::Node, kind: Definition::Kind).returns(T::Boolean) }
          def node_match_kind?(node, kind)
            case kind
            when Definition::Kind::AttrReader, Definition::Kind::AttrWriter
              node.is_a?(SyntaxTree::SymbolLiteral)
            when Definition::Kind::Class
              node.is_a?(SyntaxTree::ClassDeclaration)
            when Definition::Kind::Constant
              node.is_a?(SyntaxTree::Const) || node.is_a?(SyntaxTree::ConstPathField)
            when Definition::Kind::Method
              node.is_a?(SyntaxTree::DefNode)
            when Definition::Kind::Module
              node.is_a?(SyntaxTree::ModuleDeclaration)
            end
          end
        end

        sig { returns(T.nilable(SyntaxTree::Node)) }
        attr_reader :node

        sig { returns(T::Array[SyntaxTree::Node]) }
        attr_accessor :nodes_nesting

        sig { params(location: Location).void }
        def initialize(location)
          super()
          @location = location
          @node = T.let(nil, T.nilable(SyntaxTree::Node))
          @nodes_nesting = T.let([], T::Array[SyntaxTree::Node])
        end

        sig { override.params(node: T.nilable(SyntaxTree::Node)).void }
        def visit(node)
          return unless node

          location = location_from_node(node)

          if location == @location
            # We found the node we're looking for at `@location`
            @node = node

            # There may be a more precise child inside the node that also matches `@location`, let's visit them
            @nodes_nesting << node
            super(node)
            @nodes_nesting.pop if @nodes_nesting.last == @node
          elsif location.include?(@location)
            # The node we're looking for is inside `node`, let's visit it
            @nodes_nesting << node
            super(node)
          end
        end

        private

        # TODO: remove once SyntaxTree location are fixed
        sig { params(node: SyntaxTree::Node).returns(Location) }
        def location_from_node(node)
          case node
          when SyntaxTree::Program, SyntaxTree::BodyStmt
            # Patch SyntaxTree node locations to use the one of their children
            location_from_children(node, node.statements.body)
          when SyntaxTree::Statements
            # Patch SyntaxTree node locations to use the one of their children
            location_from_children(node, node.body)
          else
            Location.from_syntax_tree(@location.file, node.location)
          end
        end

        # TODO: remove once SyntaxTree location are fixed
        sig { params(node: SyntaxTree::Node, nodes: T::Array[SyntaxTree::Node]).returns(Location) }
        def location_from_children(node, nodes)
          first = T.must(nodes.first)
          last = T.must(nodes.last)

          Location.new(
            @location.file,
            first.location.start_line,
            first.location.start_column,
            last.location.end_line,
            last.location.end_column,
          )
        end
      end
    end
  end
end
