# typed: strict
# frozen_string_literal: true

module Spoom
  # Build a file hierarchy from a set of file paths.
  class FileTree
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_reader :strip_prefix

    sig { params(paths: T::Enumerable[String], strip_prefix: T.nilable(String)).void }
    def initialize(paths = [], strip_prefix: nil)
      @roots = T.let({}, T::Hash[String, Node])
      @strip_prefix = strip_prefix
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
      prefix = @strip_prefix
      path = path.delete_prefix("#{prefix}/") if prefix
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

    sig do
      params(
        out: T.any(IO, StringIO),
        show_strictness: T::Boolean,
        colors: T::Boolean,
        indent_level: Integer,
      ).void
    end
    def print(out: $stdout, show_strictness: true, colors: true, indent_level: 0)
      printer = TreePrinter.new(
        tree: self,
        out: out,
        show_strictness: show_strictness,
        colors: colors,
        indent_level: indent_level,
      )
      printer.print_tree
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

      sig { params(node: FileTree::Node).void}
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

    # An internal class used to print a FileTree
    #
    # See `FileTree#print`
    class TreePrinter < Spoom::Printer
      extend T::Sig

      sig { returns(FileTree) }
      attr_reader :tree

      sig do
        params(
          tree: FileTree,
          out: T.any(IO, StringIO),
          show_strictness: T::Boolean,
          colors: T::Boolean,
          indent_level: Integer,
        ).void
      end
      def initialize(tree:, out: $stdout, show_strictness: true, colors: true, indent_level: 0)
        super(out: out, colors: colors, indent_level: indent_level)
        @tree = tree
        @show_strictness = show_strictness
      end

      sig { void }
      def print_tree
        print_nodes(tree.roots)
      end

      sig { params(node: FileTree::Node).void }
      def print_node(node)
        printt
        if node.children.empty?
          if @show_strictness
            strictness = node_strictness(node)
            if @colors
              print_colored(node.name, strictness_color(strictness))
            elsif strictness
              print("#{node.name} (#{strictness})")
            else
              print(node.name.to_s)
            end
          else
            print(node.name.to_s)
          end
          print("\n")
        else
          print_colored(node.name, Color::BLUE)
          print("/")
          printn
          indent
          print_nodes(node.children.values)
          dedent
        end
      end

      sig { params(nodes: T::Array[FileTree::Node]).void }
      def print_nodes(nodes)
        nodes.each { |node| print_node(node) }
      end

      private

      sig { params(node: FileTree::Node).returns(T.nilable(String)) }
      def node_strictness(node)
        path = node.path
        prefix = tree.strip_prefix
        path = "#{prefix}/#{path}" if prefix
        Spoom::Sorbet::Sigils.file_strictness(path)
      end

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
