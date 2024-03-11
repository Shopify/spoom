# typed: strict
# frozen_string_literal: true

module Spoom
  # Build a file hierarchy from a set of file paths.
  class FileTree
    extend T::Sig

    sig { params(paths: T::Enumerable[String]).void }
    def initialize(paths = [])
      @roots = T.let({}, T::Hash[String, Node])
      add_paths(paths)
    end

    # Add all `paths` to the tree
    sig { params(paths: T::Enumerable[String]).void }
    def add_paths(paths)
      paths.each { |path| add_path(path) }
    end

    # Add a `path` to the tree
    #
    # This will create all nodes until the root of `path`.
    sig { params(path: String).returns(Node) }
    def add_path(path)
      parts = path.split("/")
      if path.empty? || parts.size == 1
        return @roots[path] ||= Node.new(parent: nil, name: path)
      end

      parent_path = T.must(parts[0...-1]).join("/")
      parent = add_path(parent_path)
      name = T.must(parts.last)
      parent.children[name] ||= Node.new(parent: parent, name: name)
    end

    # All root nodes
    sig { returns(T::Array[Node]) }
    def roots
      @roots.values
    end

    # All the nodes in this tree
    sig { returns(T::Array[Node]) }
    def nodes
      v = CollectNodes.new
      v.visit_tree(self)
      v.nodes
    end

    # All the paths in this tree
    sig { returns(T::Array[String]) }
    def paths
      nodes.map(&:path)
    end

    # Return a map of typing scores for each node in the tree
    sig { params(context: Context).returns(T::Hash[Node, Float]) }
    def nodes_strictness_scores(context)
      v = CollectScores.new(context)
      v.visit_tree(self)
      v.scores
    end

    # Return a map of typing scores for each path in the tree
    sig { params(context: Context).returns(T::Hash[String, Float]) }
    def paths_strictness_scores(context)
      nodes_strictness_scores(context).map { |node, score| [node.path, score] }.to_h
    end

    sig { params(out: T.any(IO, StringIO), colors: T::Boolean).void }
    def print(out: $stdout, colors: true)
      printer = Printer.new({}, out: out, colors: colors)
      printer.visit_tree(self)
    end

    # A node representing either a file or a directory inside a FileTree
    class Node < T::Struct
      extend T::Sig

      # Node parent or `nil` if the node is a root one
      const :parent, T.nilable(Node)

      # File or dir name
      const :name, String

      # Children of this node (if not empty, it means it's a dir)
      const :children, T::Hash[String, Node], default: {}

      # Full path to this node from root
      sig { returns(String) }
      def path
        parent = self.parent
        return name unless parent

        "#{parent.path}/#{name}"
      end
    end

    # An abstract visitor for FileTree
    class Visitor
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { params(tree: FileTree).void }
      def visit_tree(tree)
        visit_nodes(tree.roots)
      end

      sig { params(node: FileTree::Node).void }
      def visit_node(node)
        visit_nodes(node.children.values)
      end

      sig { params(nodes: T::Array[FileTree::Node]).void }
      def visit_nodes(nodes)
        nodes.each { |node| visit_node(node) }
      end
    end

    # A visitor that collects all the nodes in a tree
    class CollectNodes < Visitor
      extend T::Sig

      sig { returns(T::Array[FileTree::Node]) }
      attr_reader :nodes

      sig { void }
      def initialize
        super()
        @nodes = T.let([], T::Array[FileTree::Node])
      end

      sig { override.params(node: FileTree::Node).void }
      def visit_node(node)
        @nodes << node
        super
      end
    end

    # A visitor that collects the strictness of each node in a tree
    class CollectStrictnesses < Visitor
      extend T::Sig

      sig { returns(T::Hash[Node, T.nilable(String)]) }
      attr_reader :strictnesses

      sig { params(context: Context).void }
      def initialize(context)
        super()
        @context = context
        @strictnesses = T.let({}, T::Hash[Node, T.nilable(String)])
      end

      sig { override.params(node: FileTree::Node).void }
      def visit_node(node)
        path = node.path
        @strictnesses[node] = @context.read_file_strictness(path) if @context.file?(path)

        super
      end
    end

    # A visitor that collects the typing score of each node in a tree
    class CollectScores < CollectStrictnesses
      extend T::Sig

      sig { returns(T::Hash[Node, Float]) }
      attr_reader :scores

      sig { params(context: Context).void }
      def initialize(context)
        super
        @context = context
        @scores = T.let({}, T::Hash[Node, Float])
      end

      sig { override.params(node: FileTree::Node).void }
      def visit_node(node)
        super

        @scores[node] = node_score(node)
      end

      private

      sig { params(node: Node).returns(Float) }
      def node_score(node)
        if @context.file?(node.path)
          strictness_score(@strictnesses[node])
        else
          node.children.values.sum { |child| @scores.fetch(child, 0.0) } / node.children.size.to_f
        end
      end

      sig { params(strictness: T.nilable(String)).returns(Float) }
      def strictness_score(strictness)
        case strictness
        when "true", "strict", "strong"
          1.0
        else
          0.0
        end
      end
    end

    # An internal class used to print a FileTree
    #
    # See `FileTree#print`
    class Printer < Visitor
      extend T::Sig

      sig do
        params(
          strictnesses: T::Hash[FileTree::Node, T.nilable(String)],
          out: T.any(IO, StringIO),
          colors: T::Boolean,
        ).void
      end
      def initialize(strictnesses, out: $stdout, colors: true)
        super()
        @strictnesses = strictnesses
        @colors = colors
        @printer = T.let(Spoom::Printer.new(out: out, colors: colors), Spoom::Printer)
      end

      sig { override.params(node: FileTree::Node).void }
      def visit_node(node)
        @printer.printt
        if node.children.empty?
          strictness = @strictnesses[node]
          if @colors
            @printer.print_colored(node.name, strictness_color(strictness))
          elsif strictness
            @printer.print("#{node.name} (#{strictness})")
          else
            @printer.print(node.name.to_s)
          end
          @printer.print("\n")
        else
          @printer.print_colored(node.name, Color::BLUE)
          @printer.print("/")
          @printer.printn
          @printer.indent
          super
          @printer.dedent
        end
      end

      private

      sig { params(strictness: T.nilable(String)).returns(Color) }
      def strictness_color(strictness)
        case strictness
        when "false"
          Color::RED
        when "true", "strict", "strong"
          Color::GREEN
        else
          Color::CLEAR
        end
      end
    end
  end
end
