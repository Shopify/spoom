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
      # TODO: return if path =~ /\/test\//
      parts = path.split("/")
      if parts.size == 1
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
      all_nodes = []
      @roots.values.each { |root| collect_nodes(root, all_nodes) }
      all_nodes
    end

    # All the paths in this tree
    sig { returns(T::Array[String]) }
    def paths
      nodes.collect(&:path)
    end

    sig { params(out: T.any(IO, StringIO), show_strictness: T::Boolean, colors: T::Boolean, indent_level: Integer).void }
    def print(out: $stdout, show_strictness: true, colors: true, indent_level: 0)
      printer = TreePrinter.new(out: out, show_strictness: show_strictness, colors: colors, indent_level: indent_level)
      printer.print_tree(self)
    end

    private

    sig { params(node: FileTree::Node, collected_nodes: T::Array[Node]).returns(T::Array[String]) }
    def collect_nodes(node, collected_nodes = [])
      collected_nodes << node
      node.children.values.each { |child| collect_nodes(child, collected_nodes) }
      collected_nodes
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

      # Strictness of this file (or `nil` if no strictness or the node is a directory)
      sig { returns(T.nilable(String)) }
      def strictness
        Spoom::Sorbet::Sigils.file_strictness(path)
      end
    end

    # An internal class used to print a FileTree
    #
    # See `FileTree#print`
    class TreePrinter < Spoom::Printer
      extend T::Sig

      sig { params(out: T.any(IO, StringIO), show_strictness: T::Boolean, colors: T::Boolean, indent_level: Integer).void }
      def initialize(out: $stdout, show_strictness: true, colors: true, indent_level: 0)
        super(out: out, colors: colors, indent_level: indent_level)
        @show_strictness = show_strictness
      end

      sig { params(tree: FileTree).void }
      def print_tree(tree)
        print_nodes(tree.roots)
      end

      sig { params(node: FileTree::Node).void }
      def print_node(node)
        printt
        if node.children.empty?
          if @show_strictness
            strictness = node.strictness
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
          print_colored(node.name, :blue)
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

      sig { params(strictness: T.nilable(String)).returns(Symbol) }
      def strictness_color(strictness)
        case strictness
        when "false"
          :red
        when "true", "strict", "strong"
          :green
        else
          :uncolored
        end
      end
    end
  end
end
